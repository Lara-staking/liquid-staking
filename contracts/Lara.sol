// SPDX-License-Identifier: MIT
// Security contact: elod@apeconsulting.xyz
pragma solidity 0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IstTara} from "./interfaces/IstTara.sol";
import {ILara} from "./interfaces/ILara.sol";
import {DposInterface} from "./interfaces/IDPOS.sol";
import {IApyOracle} from "./interfaces/IApyOracle.sol";

import {NotEnoughStTARA, EpochDurationNotMet, RewardClaimFailed, StakeAmountTooLow, StakeValueTooLow, DelegationFailed, UndelegationFailed, RedelegationFailed, ConfirmUndelegationFailed, CancelUndelegationFailed} from "./libs/SharedErrors.sol";

import {Utils} from "./libs/Utils.sol";

/**
 * @title Lara Contract
 * @dev This contract is used for staking and delegating tokens in the protocol.
 */
contract Lara is Ownable, ILara {
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
    uint256 public lastEpochTotalDelegated = 0;

    uint256 public commission = 0;

    address public treasuryAddress = address(0);

    // List of delegators of the protocol
    address[] public delegators;

    // List of validators of the protocol
    address[] public validators;

    // State variable for storing a blocker bool value for the epoch runs
    bool public isEpochRunning = false;

    // StTARA token contract
    IstTara public stTaraToken;

    // DPOS contract
    DposInterface public dposContract;

    // APY oracle contract
    IApyOracle public apyOracle;

    // Array of holder data that we need to mint stTARA for after reward calculation
    Utils.HolderData[] public rewardHolderData;

    Utils.HolderData[] public undelegateRequests;

    // Mapping of the total stake at a validator
    mapping(address => uint256) public protocolTotalStakeAtValidator;

    // Mapping of the validator rating at the time of delegation
    mapping(address => uint256) public protocolValidatorRatingAtDelegation;

    // Mapping of the undelegated amount of a user
    mapping(address => uint256) public undelegated;

    /**
     * @dev Constructor for the Lara contract.
     * @param _sttaraToken The address of the stTARA token contract.
     * @param _dposContract The address of the DPOS contract.
     * @param _apyOracle The address of the APY Oracle contract.
     * @param _treasuryAddress The address of the treasury.
     */
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

    /**
     * @dev Fallback function to receive Ether.
     */
    fallback() external payable {}

    /**
     * @dev Function to receive Ether.
     */
    receive() external payable {}

    /**
     * @notice Checks if a validator is registered in the protocol
     * @param validator the validator address
     * @return true if the validator is registered, false otherwise
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

        // Register the delegator for the next stake epoch
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
        // Mint stTARA tokens to user
        try stTaraToken.mint(msg.sender, amount) {} catch Error(
            string memory reason
        ) {
            revert(reason);
        }
        emit Staked(msg.sender, amount);
    }

    /**
     * Removes the stake of a user from the protocol.
     * @notice reverts on missing approval for the amount.
     * @notice reverts if the tokens are already staked, thus not on Lara's balance.
     * The user needs to provide the amount of stTARA tokens he wants to get back as TARA
     * @param amount the amount of stTARA tokens to remove
     */
    function unstake(uint256 amount) public {
        require(
            address(this).balance >= amount,
            "LARA: Not enough assets unstaked, use requestUndelegate instead"
        );
        require(
            stTaraToken.allowance(msg.sender, address(this)) >= amount,
            "stTARA: Amount not approved for unstaking"
        );
        try stTaraToken.transferFrom(msg.sender, address(this), amount) {
            try stTaraToken.burn(address(this), amount) {
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
     * @notice method for starting a staking epoch.
     */
    function startEpoch() external {
        require(!isEpochRunning, "Epoch already running");
        uint256 remainingAmount = delegateToValidators(address(this).balance);

        stTaraToken.makeHolderSnapshot();

        uint256 totalEpochDelegation = 0;
        try dposContract.getTotalDelegation(address(this)) returns (
            uint256 totalDelegation
        ) {
            totalEpochDelegation =
                totalDelegation +
                address(this).balance -
                remainingAmount;
        } catch Error(string memory reason) {
            revert(reason);
        }
        lastEpochTotalDelegated = totalEpochDelegation;
        if (protocolStartTimestamp == 0) {
            protocolStartTimestamp = block.timestamp;
        }
        if (lastEpochTotalDelegated == 0) {
            return;
        }
        isEpochRunning = true;
        lastEpochStartBlock = block.number;
        emit EpochStarted(totalEpochDelegation, block.timestamp);
    }

    /**
     * @notice method for ending a staking epoch.
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
        try dposContract.claimAllRewards() {
            // do nothing
        } catch Error(string memory reason) {
            revert RewardClaimFailed(reason);
        }
        uint256 balanceAfter = address(this).balance;
        uint256 rewards = balanceAfter - balanceBefore;
        emit AllRewardsClaimed(rewards);
        uint256 epochCommission = (rewards * commission) / 100;
        uint256 distributableRewards = rewards - epochCommission;

        // iterate through delegators and calculate + allocate their rewards
        uint256 totalSplitRewards = 0;
        uint256 stTARASupply = stTaraToken.totalSupply();
        Utils.HolderData[] memory lastEpochHolderData = stTaraToken
            .getHolderSnapshot();
        for (uint256 i = 0; i < lastEpochHolderData.length; i++) {
            address delegator = lastEpochHolderData[i].holder;
            uint256 slice = Utils.calculateSlice(
                lastEpochHolderData[i].amount,
                stTARASupply
            );
            uint256 delegatorReward = (slice * distributableRewards) /
                100 /
                1e18;
            if (delegatorReward == 0) {
                continue;
            }
            totalSplitRewards += delegatorReward;

            //mint the reward to the delegator
            try stTaraToken.mint(delegator, delegatorReward) {} catch Error(
                string memory reason
            ) {
                revert(reason);
            }
        }
        require(
            totalSplitRewards <= distributableRewards,
            "Total split rewards exceed total rewards"
        );
        payable(treasuryAddress).transfer(epochCommission);
        emit CommissionWithdrawn(treasuryAddress, epochCommission);

        // execute undelegations
        executeUndelegations();

        isEpochRunning = false;
        emit EpochEnded(lastEpochTotalDelegated, rewards);
    }

    /**
     * @notice Rebalance method to rebalance the protocol.
     * The method is intended to be called by anyone in between epochs.
     * In this V0 there is no on-chain trigger or management function for this, will be triggered from outside.
     * The method will call the oracle to get the rebalance list and then redelegate the stake.
     */
    function rebalance() public {
        require(!isEpochRunning, "LARA: Cannot rebalance during staking epoch");
        IApyOracle.TentativeDelegation[]
            memory delegationList = buildCurrentDelegationArray();
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
     * In this V0 there is no on-chain trigger or management function for this, will be triggered from outside.
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
        require(!isEpochRunning, "Cannot redelegate during staking epoch");
        require(
            protocolTotalStakeAtValidator[from] >= amount,
            "LARA: Amount exceeds the total stake at the validator"
        );
        require(
            amount <= maxValidatorStakeCapacity,
            "LARA: Amount exceeds max stake of validators in protocol"
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
            "LARA: Msg.sender has not undelegated the amount"
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
        payable(msg.sender).transfer(balanceAfter - balanceBefore);
        emit TaraSent(msg.sender, balanceAfter - balanceBefore, block.number);
    }

    /**
     * Cancel undelegate method to cancel the undelegation of a user from a certain validator.
     * The undelegated value will be returned to the origin validator.
     * @param validator the validator from which to undelegate
     * @param amount the amount to undelegate
     */
    function cancelUndelegate(address validator, uint256 amount) public {
        require(
            undelegated[msg.sender] >= amount,
            "LARA: Msg.sender has not undelegated the amount"
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
            protocolTotalStakeAtValidator[validator] += amount;
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
    function requestUndelegate(uint256 amount) private returns (uint256) {
        require(!isEpochRunning, "Cannot undelegate during staking epoch");
        // check if the amount is approved in stTara for the protocol
        // get the stTARA tokens and burn them
        uint256 remainingAmount = amount;
        uint256 undelegatedTotal = 0;
        address[]
            memory validatorsWithDelegation = findValidatorsWithDelegation(
                amount
            );
        for (uint16 i = 0; i < validatorsWithDelegation.length; i++) {
            uint256 toUndelegate = 0;
            require(
                protocolTotalStakeAtValidator[validatorsWithDelegation[i]] <=
                    maxValidatorStakeCapacity,
                "Validator is not at max capacity"
            );
            if (
                protocolTotalStakeAtValidator[validatorsWithDelegation[i]] <
                remainingAmount
            ) {
                toUndelegate = protocolTotalStakeAtValidator[
                    validatorsWithDelegation[i]
                ];
            } else {
                toUndelegate = remainingAmount;
            }
            uint256 balanceBefore = address(this).balance;
            (bool success, bytes memory data) = address(dposContract).call(
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
            undelegatedTotal += toUndelegate;
            remainingAmount -= toUndelegate;
            uint256 balanceAfter = address(this).balance;
            protocolTotalStakeAtValidator[
                validatorsWithDelegation[i]
            ] -= toUndelegate;
            protocolValidatorRatingAtDelegation[
                validatorsWithDelegation[i]
            ] = 0;

            emit Undelegated(
                msg.sender,
                validatorsWithDelegation[i],
                toUndelegate
            );
            if (undelegatedTotal == amount) break;
        }
        require(undelegatedTotal == amount, "Cannot undelegate full amount");
        undelegated[msg.sender] += undelegatedTotal;
        return amount - undelegatedTotal;
    }

    function registerUndelegationRequest(uint256 amount) public {
        // check if the amount is approved in stTara for the protocol
        require(
            stTaraToken.allowance(msg.sender, address(this)) >= amount,
            "Amount not approved for unstaking"
        );
        // register the undelegation request
        try stTaraToken.transferFrom(msg.sender, address(this), amount) {
            try stTaraToken.burn(address(this), amount) {
                undelegateRequests.push(
                    Utils.HolderData({holder: msg.sender, amount: amount})
                );
            } catch Error(string memory reason) {
                revert(reason);
            }
        } catch Error(string memory reason) {
            revert(reason);
        }
    }

    function executeUndelegations() internal {
        for (uint256 i = 0; i < undelegateRequests.length; i++) {
            uint256 remaining = requestUndelegate(undelegateRequests[i].amount);
            if (remaining > 0) {
                undelegateRequests[i].amount = remaining;
            } else {
                undelegateRequests[i] = undelegateRequests[
                    undelegateRequests.length - 1
                ];
                undelegateRequests.pop();
            }
        }
    }

    function getValidatorsForAmount(
        uint256 amount
    ) internal returns (IApyOracle.TentativeDelegation[] memory) {
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

    function delegateToValidators(
        uint256 amount
    ) internal returns (uint256 remainingAmount) {
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
    ) internal view returns (address[] memory) {
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
        internal
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
