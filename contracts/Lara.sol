// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IstTara} from "./interfaces/IstTara.sol";
import {ILara} from "./interfaces/ILara.sol";
import {DposInterface} from "./interfaces/IDPOS.sol";
import {IApyOracle} from "./interfaces/IApyOracle.sol";

import {EpochDurationNotMet, RewardClaimFailed, StakeAmountTooLow, StakeValueTooLow, DelegationFailed, UndelegationFailed, RedelegationFailed, ConfirmUndelegationFailed, CancelUndelegationFailed} from "./errors/SharedErrors.sol";

contract Lara is Ownable, ILara {
    // State variables

    // Reference timestamp for computing epoch number
    uint256 public protocolStartTimestamp;

    uint256 public lastEpochStartBlock;

    // Duration of an epoch in seconds, initially 1000 blocks
    uint256 public epochDuration = 1000;

    // Maximum staking capacity for a validator
    uint256 public maxValidatorStakeCapacity = 80000000 ether;

    // Minimum amount allowed for staking
    uint256 public minStakeAmount = 1000 ether;

    // State variable for storing the last epoch's total delegated amount
    uint256 public lastEpochTotalDelegatedAmount = 0;

    uint256 public commission = 0;
    // List of delegators of the protocol
    // List of validators of the protocol
    address[] public delegators;

    address[] public validators;

    address public treasuryAddress = address(0);

    // State variable for storing a blocker bool value for the epoch runs
    bool public isEpochRunning = false;

    // StTARA token contract
    IstTara public stTaraToken;

    // DPOS contract
    DposInterface public dposContract;

    // APY oracle contract
    IApyOracle public apyOracle;

    // Mapping of the total stake at a validator
    mapping(address => uint256) public protocolTotalStakeAtValidator;

    // Mapping of the validator rating at the time of delegation
    mapping(address => uint256) public protocolValidatorRatingAtDelegation;

    // Mapping of the compounding status of a user
    mapping(address => bool) public isCompounding;

    // Mapping of the staked but not yet delegated amount of a user
    mapping(address => uint256) public stakedAmounts;

    // Mapping of the delegated amount of a user
    mapping(address => uint256) public delegatedAmounts;

    // Mapping of the claimable rewards of a user
    mapping(address => uint256) public claimableRewards;

    // Mapping of the undelegated amount of a user
    mapping(address => uint256) public undelegated;

    constructor(
        address _sttaraToken,
        address _dposContract,
        address _apyOracle,
        address _treasuryAddress
    ) Ownable(msg.sender) {
        stTaraToken = IstTara(_sttaraToken);
        dposContract = DposInterface(_dposContract);
        apyOracle = IApyOracle(_apyOracle);
        treasuryAddress = _treasuryAddress;
    }

    fallback() external payable {}

    receive() external payable {}

    /**
     * @notice Getter for a certain delegator at a certain index
     * @param index the index of the delegator
     */
    function getDelegatorAtIndex(uint256 index) public view returns (address) {
        return delegators[index];
    }

    /**
     * Checks if a validator is registered in the protocol
     * @param validator the validator address
     */
    function isValidatorRegistered(
        address validator
    ) public view returns (bool) {
        return protocolTotalStakeAtValidator[validator] > 0;
    }

    /**
     * @notice Setter for epochDuration
     * @param _epochDuration new epoch duration (in seconds)
     */
    function setEpochDuration(uint256 _epochDuration) public onlyOwner {
        epochDuration = _epochDuration;
    }

    /**
     * @notice Setter for commission
     * @param _commission new commission
     */
    function setCommission(uint256 _commission) public onlyOwner {
        commission = _commission;
        emit CommissionChanged(_commission);
    }

    /**
     * @notice Setter for treasuryAddress
     * @param _treasuryAddress new treasuryAddress
     */
    function setTreasuryAddress(address _treasuryAddress) public onlyOwner {
        treasuryAddress = _treasuryAddress;
        emit TreasuryChanged(_treasuryAddress);
    }

    /**
     * @notice Setter for compounding
     * @param value the new value for compounding(T/F)
     */
    function setCompound(bool value) public {
        isCompounding[msg.sender] = value;
        emit CompoundChanged(msg.sender, value);
    }

    /**
     * @notice onlyOwner Setter for maxValidatorStakeCapacity
     * @param _maxValidatorStakeCapacity new maxValidatorStakeCapacity
     */
    function setMaxValidatorStakeCapacity(
        uint256 _maxValidatorStakeCapacity
    ) external onlyOwner {
        maxValidatorStakeCapacity = _maxValidatorStakeCapacity;
    }

    /**
     * @notice onlyOwner Setter for minStakeAmount
     * @param _minStakeAmount the new minStakeAmount
     */
    function setMinStakeAmount(uint256 _minStakeAmount) external onlyOwner {
        minStakeAmount = _minStakeAmount;
    }

    /**
     * @notice Stake function
     * In the stake function, the user sends the amount of TARA tokens he wants to stake.
     * This method takes the payment and mints the stTARA tokens to the user.
     * @notice The tokens are not DELEGATED INSTANTLY, but on the next epoch.
     * @param amount the amount to stake
     */
    function stake(uint256 amount) public payable {
        if (amount < minStakeAmount)
            revert StakeAmountTooLow(amount, minStakeAmount);
        if (msg.value < amount) revert StakeValueTooLow(msg.value, amount);

        // Register the validator for the next stake epoch
        bool isRegistered = false;
        for (uint32 i = 0; i < delegators.length; i++) {
            if (delegators[i] == msg.sender) {
                isRegistered = true;
                break;
            }
        }
        if (!isRegistered) {
            delegators.push(msg.sender);
        }
        stakedAmounts[msg.sender] += amount;

        // Mint stTARA tokens to user
        try stTaraToken.mint(msg.sender, amount) {} catch Error(
            string memory reason
        ) {
            revert(reason);
        }

        emit Staked(msg.sender, amount);
    }

    event DelegationArray(IApyOracle.TentativeDelegation[]);

    function rebalance() public {
        require(
            isEpochRunning == false,
            "Cannot rebalance during staking epoch"
        );
        IApyOracle.TentativeDelegation[]
            memory delegationList = buildCurrentDelegationArray();
        emit DelegationArray(delegationList);
        // Get the rebalance list from the oracle
        try apyOracle.getRebalanceList(delegationList) returns (
            IApyOracle.TentativeReDelegation[] memory rebalanceList
        ) {
            // Go through the rebalance list and redelegate
            for (uint256 i = 0; i < rebalanceList.length; i++) {
                reDelegate(
                    rebalanceList[i].from,
                    rebalanceList[i].to,
                    rebalanceList[i].amount,
                    rebalanceList[i].toRating
                );
            }
        } catch Error(string memory reason) {
            revert(reason);
        }
    }

    /**
     * ReDelegate method to move stake from one validator to another inside the protocol.
     * The method is intended to be called by the protocol owner on a need basis.
     * In this V0 there is no on-chain trigger or management function for this, will be triggere from outside.
     * @param from the validator from which to move stake
     * @param to the validator to which to move stake
     * @param amount the amount to move
     */
    function reDelegate(
        address from,
        address to,
        uint256 amount,
        uint256 rating
    ) internal {
        require(
            isEpochRunning == false,
            "Cannot redelegate during staking epoch"
        );
        require(
            protocolTotalStakeAtValidator[from] >= amount,
            "Amount exceeds the total stake at the validator"
        );
        require(
            amount <= maxValidatorStakeCapacity,
            "Amount exceeds max stake of validators in protocol"
        );
        uint256 balanceBefore = address(this).balance;
        (bool success, bytes memory data) = address(dposContract).call(
            abi.encodeWithSignature(
                "reDelegate(address,address,uint256)",
                from,
                to,
                amount
            )
        );
        if (!success)
            revert RedelegationFailed(
                from,
                to,
                amount,
                abi.decode(data, (string))
            );
        uint256 balanceAfter = address(this).balance;
        // send this amount to the treasury as it is minimal
        payable(treasuryAddress).transfer(balanceAfter - balanceBefore);
        emit RedelegationRewardsClaimed(balanceAfter - balanceBefore, from);
        emit TaraSent(
            treasuryAddress,
            balanceAfter - balanceBefore,
            block.number
        );

        protocolTotalStakeAtValidator[from] -= amount;
        protocolValidatorRatingAtDelegation[from] = 0;
        protocolTotalStakeAtValidator[to] += amount;
        protocolValidatorRatingAtDelegation[to] = rating;
    }

    /**
     * Confirm undelegate method to confirm the undelegation of a user from a certain validator.
     * Will fail if called before the undelegation period is over.
     * @param validator the validator from which to undelegate
     * @param amount the amount to undelegate
     * @notice msg.sender is the delegator
     */
    function confirmUndelegate(address validator, uint256 amount) public {
        require(
            undelegated[msg.sender] >= amount,
            "Msg.sender has not undelegated the amount"
        );
        uint256 balanceBefore = address(this).balance;
        (bool success, bytes memory data) = address(dposContract).call(
            abi.encodeWithSignature("confirmUndelegate(address)", validator)
        );
        if (!success)
            revert ConfirmUndelegationFailed(
                msg.sender,
                validator,
                amount,
                abi.decode(data, (string))
            );
        undelegated[msg.sender] -= amount;
        uint256 balanceAfter = address(this).balance;
        // we need to send the rewards to the user
        uint256 claimCommission = ((balanceAfter - balanceBefore) *
            commission) / 100;
        payable(msg.sender).transfer(
            balanceAfter - balanceBefore - claimCommission
        );
        emit TaraSent(
            msg.sender,
            balanceAfter - balanceBefore - claimCommission,
            block.number
        );
        if (claimCommission > 0) {
            payable(treasuryAddress).transfer(claimCommission);
            emit CommissionWithdrawn(msg.sender, claimCommission);
        }
    }

    /**
     * Cancel undelegate method to cancel the undelegation of a user from a certain validator.
     * The undelegated value will be returned to the origin validator.
     * @param validator the validator from which to undelegate
     * @param amount the amount to undelegate
     */
    function cancelUndelegate(address validator, uint256 amount) public {
        require(!isEpochRunning, "Cannot undelegate during staking epoch");
        require(
            undelegated[msg.sender] >= amount,
            "Msg.sender has not undelegated the amount"
        );
        (bool success, bytes memory data) = address(dposContract).call(
            abi.encodeWithSignature("cancelUndelegate(address)", validator)
        );
        if (!success)
            revert CancelUndelegationFailed(
                msg.sender,
                validator,
                amount,
                abi.decode(data, (string))
            );
        try stTaraToken.mint(msg.sender, amount) {
            undelegated[msg.sender] -= amount;
            delegatedAmounts[msg.sender] += amount;
            protocolTotalStakeAtValidator[validator] += amount;
        } catch Error(string memory reason) {
            revert(reason);
        }
    }

    /**
     * Removes the stake of a user from the protocol.
     * @notice reverts on missing approval for the amount.
     * The user needs to provide the amount of stTARA tokens he wants to get back as TARA
     * @param amount the amount of stTARA tokens to remove
     */
    function removeStake(uint256 amount) public {
        require(
            stakedAmounts[msg.sender] >= amount,
            "Amount exceeds the user's stake"
        );
        require(
            stTaraToken.allowance(msg.sender, address(this)) >= amount,
            "Amount not approved for unstaking"
        );
        try stTaraToken.transferFrom(msg.sender, address(this), amount) {
            try stTaraToken.burn(address(this), amount) {
                stakedAmounts[msg.sender] -= amount;
                payable(msg.sender).transfer(amount);
                emit StakeRemoved(msg.sender, amount);
                emit TaraSent(msg.sender, amount, block.number);
            } catch Error(string memory reason) {
                revert(reason);
            }
        } catch Error(string memory reason) {
            revert(reason);
        }
    }

    /**
     * Undelegates the amount from one or more validators.
     * The user needs to provide the amount of stTARA tokens he wants to undelegate. The protocol will burn them.
     * @notice reverts on missing approval for the amount.
     * @param amount the amount of tokens to undelegate
     */
    function requestUndelegate(uint256 amount) public {
        require(!isEpochRunning, "Cannot undelegate during staking epoch");
        // check if the amount is approved in stTara for the protocol
        require(
            stTaraToken.allowance(msg.sender, address(this)) >= amount,
            "Amount not approved for unstaking"
        );
        uint256 userDelegation = delegatedAmounts[msg.sender];
        require(userDelegation >= amount, "Amount exceeds user's delegation");

        // get the stTARA tokens and burn them
        try stTaraToken.transferFrom(msg.sender, address(this), amount) {
            try stTaraToken.burn(address(this), amount) {
                uint256 remainingAmount = amount;
                uint256 undelegatedTotal = 0;
                address[]
                    memory validatorsWithDelegation = findValidatorsWithDelegation(
                        amount
                    );
                for (uint16 i = 0; i < validatorsWithDelegation.length; i++) {
                    uint256 toUndelegate = 0;
                    require(
                        protocolTotalStakeAtValidator[
                            validatorsWithDelegation[i]
                        ] <= maxValidatorStakeCapacity,
                        "Validator is not at max capacity"
                    );
                    if (
                        protocolTotalStakeAtValidator[
                            validatorsWithDelegation[i]
                        ] < remainingAmount
                    ) {
                        toUndelegate = protocolTotalStakeAtValidator[
                            validatorsWithDelegation[i]
                        ];
                    } else {
                        toUndelegate = remainingAmount;
                    }
                    uint256 balanceBefore = address(this).balance;
                    (bool success, bytes memory data) = address(dposContract)
                        .call(
                            abi.encodeWithSignature(
                                "undelegate(address,uint256)",
                                validatorsWithDelegation[i],
                                toUndelegate
                            )
                        );
                    if (!success)
                        revert UndelegationFailed(
                            validatorsWithDelegation[i],
                            msg.sender,
                            toUndelegate,
                            abi.decode(data, (string))
                        );
                    delegatedAmounts[msg.sender] -= toUndelegate;
                    undelegatedTotal += toUndelegate;
                    remainingAmount -= toUndelegate;
                    uint256 balanceAfter = address(this).balance;
                    protocolTotalStakeAtValidator[
                        validatorsWithDelegation[i]
                    ] -= toUndelegate;
                    protocolValidatorRatingAtDelegation[
                        validatorsWithDelegation[i]
                    ] = 0;

                    // we need to send the rewards to the user
                    payable(msg.sender).transfer(balanceAfter - balanceBefore);
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
                    emit TaraSent(
                        msg.sender,
                        balanceAfter - balanceBefore,
                        block.number
                    );
                    if (undelegatedTotal == amount) break;
                }
                require(
                    undelegatedTotal == amount,
                    "Cannot undelegate full amount"
                );
                undelegated[msg.sender] += undelegatedTotal;
            } catch Error(string memory reason) {
                revert(reason);
            }
        } catch Error(string memory reason) {
            revert(reason);
        }
    }

    /**
     * Public method for claiming rewards.
     * The user can claim his rewards at any time but if there is an epoch running, he will only get the rewards from the last epoch.
     * Pays rewards in TARA.
     */
    function claimRewards() public {
        uint256 amount = claimableRewards[msg.sender];
        require(amount > 0, "No rewards to claim");
        require(address(this).balance >= amount, "Not enough balance to claim");
        claimableRewards[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        emit RewardsClaimed(msg.sender, amount, block.timestamp);
        emit TaraSent(msg.sender, amount, block.number);
    }

    /**
     * Private method for delegating the stake of a user to the validators.
     * @param user the user for which to delegate
     */
    function delegateStakeOfUser(address user) public onlyOwner {
        uint256 amount = stakedAmounts[user];
        if (isCompounding[user]) {
            amount += claimableRewards[user];
            claimableRewards[user] = 0;
        }
        if (amount == 0) return; // causes underflow if not checked
        uint256 remainingAmount = delegateToValidators(amount);
        uint256 diffDelegated = amount - remainingAmount;
        delegatedAmounts[user] += diffDelegated;
        if (stakedAmounts[user] != 0) {
            // this is to avoid the scenario where the user autocompounds but has no stakedAmounts to subtract from
            stakedAmounts[user] -= diffDelegated;
        }
        emit Delegated(user, diffDelegated);
    }

    /**
     * @notice OnlyOwner method for starting a staking epoch.
     */
    function startEpoch() external {
        require(!isEpochRunning, "Epoch already running");
        uint256 totalEpochDelegation = 0;
        for (uint32 i = 0; i < delegators.length; i++) {
            delegateStakeOfUser(delegators[i]);
            totalEpochDelegation += delegatedAmounts[delegators[i]];
        }
        lastEpochTotalDelegatedAmount = totalEpochDelegation;
        if (protocolStartTimestamp == 0) {
            protocolStartTimestamp = block.timestamp;
        }
        isEpochRunning = true;
        lastEpochStartBlock = block.number;
        emit EpochStarted(totalEpochDelegation, block.timestamp);
    }

    /**
     * @notice OnlyOwner method for ending a staking epoch.
     */
    function endEpoch() public {
        require(isEpochRunning, "Epoch not running");
        if (block.number < lastEpochStartBlock + epochDuration) {
            revert EpochDurationNotMet(
                lastEpochStartBlock,
                block.number,
                epochDuration
            );
        }
        uint256 balanceBefore = address(this).balance;
        uint32 batch = 0;
        bool end = false;
        while (!end) {
            (bool success, bytes memory value) = address(dposContract).call(
                abi.encodeWithSignature("claimAllRewards(uint32)", batch)
            );
            if (!success) revert RewardClaimFailed(batch);
            bool _end = abi.decode(value, (bool));
            end = _end;
            batch++;
        }
        uint256 balanceAfter = address(this).balance;
        uint256 rewards = balanceAfter - balanceBefore;
        emit AllRewardsClaimed(rewards);
        uint256 epochCommission = (rewards * commission) / 100;
        uint256 epochTreasury = rewards - epochCommission;

        // iterate through delegators and calculate + allocate their rewards
        uint256 totalSplitRewards = 0;
        for (uint256 i = 0; i < delegators.length; i++) {
            address delegator = delegators[i];
            uint256 delegatorReward = (delegatedAmounts[delegator] *
                epochTreasury) / lastEpochTotalDelegatedAmount;
            if (delegatorReward == 0) {
                continue;
            }
            claimableRewards[delegator] += delegatorReward;
            totalSplitRewards += delegatorReward;
            emit RewardsClaimed(delegator, delegatorReward, block.timestamp);
        }
        require(
            totalSplitRewards <= epochTreasury,
            "Total split rewards exceed total rewards"
        );
        payable(treasuryAddress).transfer(epochCommission);
        emit CommissionWithdrawn(treasuryAddress, epochCommission);
        isEpochRunning = false;
        emit EpochEnded(
            lastEpochTotalDelegatedAmount,
            rewards,
            block.timestamp
        );
    }

    function getValidatorsForAmount(
        uint256 amount
    ) public returns (IApyOracle.TentativeDelegation[] memory) {
        try apyOracle.getNodesForDelegation(amount) returns (
            IApyOracle.TentativeDelegation[] memory nodesList
        ) {
            if (nodesList.length == 0)
                revert("No nodes available for delegation");
            return nodesList;
        } catch Error(string memory reason) {
            revert(reason);
        }
    }

    function delegateToDpos(address validator) public payable {
        (bool success, ) = address(dposContract).call{
            value: msg.value,
            gas: 300000
        }(abi.encodeWithSignature("delegate(address)", validator));
        if (!success) revert("Delegation failed");
    }

    function delegateToValidators(
        uint256 amount
    ) public returns (uint256 remainingAmount) {
        uint256 delegatedAmount = 0;
        IApyOracle.TentativeDelegation[]
            memory nodesList = getValidatorsForAmount(amount);
        if (nodesList.length == 0) {
            revert("No nodes available for delegation");
        }
        for (uint256 i = 0; i < nodesList.length; i++) {
            if (delegatedAmount == amount) break;
            (bool success, bytes memory data) = address(dposContract).call{
                value: nodesList[i].amount
            }(
                abi.encodeWithSignature(
                    "delegate(address)",
                    nodesList[i].validator
                )
            );
            if (!success)
                revert DelegationFailed(
                    nodesList[i].validator,
                    msg.sender,
                    nodesList[i].amount,
                    abi.decode(data, (string))
                );
            delegatedAmount += nodesList[i].amount;
            if (!isValidatorRegistered(nodesList[i].validator)) {
                validators.push(nodesList[i].validator);
            }
            protocolTotalStakeAtValidator[nodesList[i].validator] += nodesList[
                i
            ].amount;
            protocolValidatorRatingAtDelegation[
                nodesList[i].validator
            ] = nodesList[i].rating;
        }
        return amount - delegatedAmount;
    }

    function findValidatorsWithDelegation(
        uint256 amount
    ) private view returns (address[] memory) {
        uint8 count = 0;
        uint256 stakeRequired = amount;
        for (uint256 i = 0; i < validators.length; i++) {
            count++;
            if (
                stakeRequired <= 0 ||
                stakeRequired <= protocolTotalStakeAtValidator[validators[i]]
            ) {
                break;
            } else {
                stakeRequired -= protocolTotalStakeAtValidator[validators[i]];
            }
        }
        address[] memory result = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = validators[i];
        }
        return result;
    }

    function buildCurrentDelegationArray()
        private
        view
        returns (IApyOracle.TentativeDelegation[] memory)
    {
        IApyOracle.TentativeDelegation[]
            memory result = new IApyOracle.TentativeDelegation[](
                validators.length
            );
        for (uint256 i = 0; i < validators.length; i++) {
            result[i] = IApyOracle.TentativeDelegation(
                validators[i],
                protocolTotalStakeAtValidator[validators[i]],
                protocolValidatorRatingAtDelegation[validators[i]]
            );
        }
        return result;
    }
}
