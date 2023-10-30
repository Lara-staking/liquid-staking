// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IstTara} from "./interfaces/IstTara.sol";
import {DposInterface} from "./interfaces/IDPOS.sol";
import {IApyOracle} from "./interfaces/IApyOracle.sol";
import {INodeContinuityOracle} from "./interfaces/INodeContinuityOracle.sol";

import {RewardClaimFailed, StakeAmountTooLow, StakeValueTooLow, DelegationFailed} from "./errors/SharedErrors.sol";

contract Lara is Ownable {
    // Events
    event Staked(address indexed user, uint256 amount);
    event Delegated(address indexed user, uint256 amount);
    event EpochStarted(uint256 totalEpochDelegation, uint256 timestamp);
    event RewardsClaimed(
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );
    event EpochEnded(
        uint256 totalEpochDelegation,
        uint256 totalEpochReward,
        uint256 timestamp
    );
    event Undelegated(
        address indexed user,
        address indexed validator,
        uint256 amount
    );

    modifier onlyUser(address user) {
        require(
            msg.sender == user,
            "Invalid set: you can set compounding only for yourself"
        );
        _;
    }

    // State variables

    // Reference timestamp for computing epoch number
    uint256 public protocolStartTimestamp;

    // Duration of an epoch in seconds, initially 1000 blocks
    uint256 public epochDuration = 1000;

    // Maximum staking capacity for a validator
    uint256 public maxValidatorStakeCapacity = 80000000 ether;

    // Minimum amount allowed for staking
    uint256 public minStakeAmount = 1000 ether;

    // StTARA token contract
    IstTara public stTaraToken;

    // DPOS contract
    DposInterface public dposContract;

    // APY oracle contract
    IApyOracle public apyOracle;

    address[] public delegators;
    address[] public validators;
    mapping(address => uint256) public protocolTotalStakeAtValidator;
    mapping(address => bool) public isCompounding;
    mapping(address => uint256) public stakedAmounts; //=> 1000 TARA => 0 TARA => 1000 TARA => 0 TARA => 28 TARA
    mapping(address => uint256) public delegatedAmounts; //=> 1000 TARA => 2000 TARA => 2028 TARA
    mapping(address => uint256) public claimableRewards; //=> 14 TARA => 0 TARA => 28 TARA => 0 TARA
    mapping(address => uint256) public undelegated;
    uint256 public lastEpochTotalDelegatedAmount = 0;

    constructor(
        address _sttaraToken,
        address _dposContract,
        address _apyOracle
    ) {
        stTaraToken = IstTara(_sttaraToken);
        dposContract = DposInterface(_dposContract);
        apyOracle = IApyOracle(_apyOracle);
    }

    fallback() external payable {}

    receive() external payable {}

    function getDelegatorAtIndex(uint256 index) public view returns (address) {
        return delegators[index];
    }

    /**
     * @notice Setter for epochDuration
     * @param _epochDuration new epoch duration (in seconds)
     */
    function setEpochDuration(uint256 _epochDuration) public onlyOwner {
        epochDuration = _epochDuration;
    }

    /**
     * @notice Setter for compounding
     * @param user the user for which to set compounding
     * @param value the new value for compounding(T/F)
     */
    function setCompounding(address user, bool value) public onlyUser(user) {
        isCompounding[user] = value;
    }

    function stake(uint256 amount) public payable {
        if (amount < minStakeAmount)
            revert StakeAmountTooLow(amount, minStakeAmount);
        if (msg.value < amount) revert StakeValueTooLow(msg.value, amount);

        // Register the validator for the next stake epoch
        delegators.push(msg.sender);
        stakedAmounts[msg.sender] += amount;

        // Mint stTARA tokens to user
        try stTaraToken.mint(msg.sender, amount) {} catch {
            revert("Mint failed");
        }

        emit Staked(msg.sender, amount);
    }

    function confirmUndelegate(address validator, uint256 amount) public {
        require(
            undelegated[msg.sender] >= amount,
            "Msg.sender has not undelegated the amount"
        );
        uint256 balanceBefore = address(this).balance;
        try dposContract.confirmUndelegate(validator) {
            undelegated[msg.sender] -= amount;
            uint256 balanceAfter = address(this).balance;
            // we need to send the rewards to the user
            payable(msg.sender).transfer(balanceAfter - balanceBefore);
        } catch {
            revert("Confirm undelegate failed");
        }
    }

    function cancelUndelegate(address validator, uint256 amount) public {
        require(
            undelegated[msg.sender] >= amount,
            "Msg.sender has not undelegated the amount"
        );
        try dposContract.cancelUndelegate(validator) {
            undelegated[msg.sender] -= amount;
            delegatedAmounts[msg.sender] += amount;
        } catch {
            revert("Cancel undelegate failed");
        }
    }

    function requestUndelegate(uint256 amount) public {
        // check if the amount is approved in stTara for the protocol
        require(
            stTaraToken.allowance(msg.sender, address(this)) >= amount,
            "Amount not approved for unstaking"
        );
        uint256 userDelegation = delegatedAmounts[msg.sender];
        require(userDelegation > 0, "No delegations found for the user");
        require(userDelegation >= amount, "Amount exceeds user's delegation");

        // get the stTARA tokens and burn them
        try stTaraToken.transferFrom(msg.sender, address(this), amount) {
            try stTaraToken.burn(address(this), amount) {
                uint256 undelegatedTotal = 0;
                address[]
                    memory validatorsWithDelegation = findValidatorsWithDelegation(
                        amount
                    );
                for (uint16 i = 0; i <= validatorsWithDelegation.length; i++) {
                    uint256 toUndelegate = 0;
                    if (
                        protocolTotalStakeAtValidator[
                            validatorsWithDelegation[i]
                        ] < amount
                    ) {
                        toUndelegate = protocolTotalStakeAtValidator[
                            validatorsWithDelegation[i]
                        ];
                    } else {
                        toUndelegate = amount;
                    }
                    uint256 balanceBefore = address(this).balance;
                    try
                        dposContract.undelegate(
                            validatorsWithDelegation[i],
                            toUndelegate
                        )
                    {
                        delegatedAmounts[msg.sender] -= toUndelegate;
                        undelegatedTotal += toUndelegate;
                        uint256 balanceAfter = address(this).balance;

                        // we need to send the rewards to the user
                        payable(msg.sender).transfer(
                            balanceAfter - balanceBefore
                        );
                        emit Undelegated(
                            msg.sender,
                            validatorsWithDelegation[i],
                            toUndelegate
                        );
                        emit RewardsClaimed(
                            msg.sender,
                            balanceAfter - balanceBefore,
                            block.timestamp
                        );
                    } catch {
                        revert("Undelegation failed");
                    }
                }
            } catch {
                revert("Burn failed");
            }
        } catch {
            revert("TransferFrom failed");
        }
    }

    function claimRewards() public {
        uint256 amount = claimableRewards[msg.sender];
        if (amount == 0) return;
        claimableRewards[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        emit RewardsClaimed(msg.sender, amount, block.timestamp);
    }

    function delegateStakeOfUser(address user) private onlyOwner {
        uint256 amount = stakedAmounts[user];
        if (isCompounding[user]) {
            amount += claimableRewards[user];
            claimableRewards[user] = 0;
        }
        uint256 remainingAmount = delegateToValidators(amount);
        uint256 diffDelegated = amount - remainingAmount;
        delegatedAmounts[user] += diffDelegated;
        stakedAmounts[user] -= diffDelegated;
        emit Delegated(user, diffDelegated);
    }

    function startEpoch() external onlyOwner {
        uint256 totalEpochDelegation = 0;
        for (uint256 i = 0; i < delegators.length; i++) {
            totalEpochDelegation += stakedAmounts[delegators[i]];
        }
        for (uint256 i = 0; i < delegators.length; i++) {
            delegateStakeOfUser(delegators[i]);
        }
        lastEpochTotalDelegatedAmount = totalEpochDelegation;
        if (protocolStartTimestamp == 0) {
            protocolStartTimestamp = block.timestamp;
        }
        emit EpochStarted(totalEpochDelegation, block.timestamp);
    }

    function endEpoch() public onlyOwner {
        uint256 balanceBefore = address(this).balance;
        uint32 batch = 1;
        bool end = false;
        while (!end) {
            try dposContract.claimAllRewards(batch) returns (bool _end) {
                end = _end;
                batch++;
            } catch {
                revert RewardClaimFailed();
            }
        }
        uint256 balanceAfter = address(this).balance;
        uint256 rewards = balanceAfter - balanceBefore;

        // iterate through delegators and calculate + allocate their rewards
        for (uint256 i = 0; i < delegators.length; i++) {
            address delegator = delegators[i];
            uint256 delegatorReward = (delegatedAmounts[delegator] * rewards) /
                lastEpochTotalDelegatedAmount;
            claimableRewards[delegator] += delegatorReward;
            emit RewardsClaimed(delegator, delegatorReward, block.timestamp);
        }
        emit EpochEnded(
            lastEpochTotalDelegatedAmount,
            rewards,
            block.timestamp
        );
    }

    function delegateToValidators(
        uint256 amount
    ) internal returns (uint256 remainingAmount) {
        uint256 delegatedAmount = 0;
        IApyOracle.TentativeDelegation[] memory nodesList = apyOracle
            .getNodesForDelegation(amount);
        for (uint256 i = 0; i < nodesList.length; i++) {
            if (delegatedAmount == amount) break;
            try
                dposContract.delegate{value: nodesList[i].amount}(
                    nodesList[i].validator
                )
            {
                delegatedAmount += nodesList[i].amount;
                if (!isValidatorRegistered(nodesList[i].validator)) {
                    validators.push(nodesList[i].validator);
                }
                protocolTotalStakeAtValidator[
                    nodesList[i].validator
                ] += nodesList[i].amount;
            } catch {
                revert DelegationFailed(
                    nodesList[i].validator,
                    msg.sender,
                    amount
                );
            }
        }
        return amount - delegatedAmount;
    }

    function isValidatorRegistered(
        address validator
    ) public view returns (bool) {
        return protocolTotalStakeAtValidator[validator] > 0;
    }

    function findValidatorsWithDelegation(
        uint256 amount
    ) private view returns (address[] memory) {
        uint8 count = 0;
        uint256 stakeRequired = 0;
        for (uint256 i = 0; i < validators.length; i++) {
            if (stakeRequired <= amount) {
                count++;
                stakeRequired += protocolTotalStakeAtValidator[validators[i]];
            } else {
                break;
            }
        }
        address[] memory result = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = validators[i];
        }
        return result;
    }

    function setMaxValidatorStakeCapacity(
        uint256 _maxValidatorStakeCapacity
    ) external onlyOwner {
        maxValidatorStakeCapacity = _maxValidatorStakeCapacity;
    }

    function setMinStakeAmount(uint256 _minStakeAmount) external onlyOwner {
        minStakeAmount = _minStakeAmount;
    }
}
