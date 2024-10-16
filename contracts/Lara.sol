// SPDX-License-Identifier: MIT
// Security contact: elod@apeconsulting.xyz
pragma solidity 0.8.20;

import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import {IstTara} from "./interfaces/IstTara.sol";
import {ILara} from "./interfaces/ILara.sol";
import {DposInterface} from "./interfaces/IDPOS.sol";
import {IApyOracle} from "./interfaces/IApyOracle.sol";

import {
    NoDelegation,
    NotEnoughStTARA,
    EpochDurationNotMet,
    RewardClaimFailed,
    StakeAmountTooLow,
    StakeValueIncorrect,
    DelegationFailed,
    UndelegationFailed,
    RedelegationFailed,
    ConfirmUndelegationFailed,
    CancelUndelegationFailed,
    UndelegationNotFound,
    UndelegationsNotMatching,
    TransferFailed,
    SnapshotNotFound,
    SnapshotAlreadyClaimed,
    ZeroAddress
} from "./libs/SharedErrors.sol";

/**
 * @title Lara Contract
 * @dev This contract is used for staking and delegating tokens in the protocol.
 */
contract Lara is Ownable2StepUpgradeable, UUPSUpgradeable, ILara, ReentrancyGuardUpgradeable {
    /// @dev Reference timestamp for computing systme health
    uint256 public protocolStartTimestamp;
    /// @dev Last snapshot timestamp
    uint256 public lastSnapshotBlock;
    /// @dev Last snapshot ID
    uint256 public lastSnapshotId;
    /// @dev Last rebalance timestamp
    uint256 public lastRebalance;

    /// @dev Duration of an epoch in seconds, initially 1000 blocks
    uint256 public epochDuration;

    /// @dev Maximum staking capacity for a validator
    uint256 public maxValidatorStakeCapacity;

    /// @dev Minimum amount allowed for staking
    uint256 public minStakeAmount;

    /// @dev Protocol-level general commission percentage for rewards distribution
    uint256 public commission;

    /// @dev Address of the protocol treasury
    address public treasuryAddress;

    /// @dev StTARA token contract
    IstTara public stTaraToken;

    /// @dev DPOS contract
    DposInterface public dposContract;

    /// @dev APY oracle contract
    IApyOracle public apyOracle;

    /// @dev Mapping of the total stakes at a validator. Should be regularly updated
    /// It should be a proxy of the DPOS contract delegations to a specific validator
    mapping(address => uint256) public protocolTotalStakeAtValidator;

    /// @dev Mapping of the validator rating at the time of delegation
    /// It should be updated or set to zero when a validator is unregistered(has no delegation from Lara)
    mapping(address => uint256) public protocolValidatorRatingAtDelegation;

    /// @dev Mapping of the total undelegated amounts of a user
    mapping(address => uint256) public undelegated;

    /// @dev Mapping of individual undelegations by user
    /// Should be a proxy to the undelegations in the DPOS contract, but we keep them in-memory for gas efficiency
    mapping(address => mapping(uint64 => DposInterface.UndelegationV2Data)) public undelegations;

    /// @dev Mapping of LARA staking commission discounts for staker addresses. Init values are 0 for all addresses, increasing linearly as per the
    /// staking tokenomics. 1 unit means 1% increase to the epoch minted stTARA tokens.
    mapping(address => uint32) public commissionDiscounts;

    /// @dev Mapping of the non-commission rewards per snapshot
    mapping(uint256 => uint256) public rewardsPerSnapshot;

    /// @dev Mapping of the staker snapshot claimed status
    mapping(address => mapping(uint256 => bool)) public stakerSnapshotClaimed;

    /// @dev Gap for future upgrades. In case of new storage variables, they should be added before this gap and the array length should be reduced
    uint256[49] __gap;

    // Event declarations
    event CommissionDiscountUpdated(address indexed staker, uint32 discount);
    event EpochDurationUpdated(uint256 oldEpochDuration, uint256 newEpochDuration);
    event MaxValidatorStakeCapacityUpdated(uint256 oldCapacity, uint256 newCapacity);
    event MinStakeAmountUpdated(uint256 oldMinStakeAmount, uint256 newMinStakeAmount);
    event UndelegationCancelled(address indexed staker, address indexed validator, uint64 id, uint256 amount);
    event DelegationSynced(address indexed account, uint256 stake);
    event ValidatorRatingReset(address indexed account);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializer for the Lara contract.
     * @param _sttaraToken The address of the stTARA token contract.
     * @param _dposContract The address of the DPOS contract.
     * @param _apyOracle The address of the APY Oracle contract.
     * @param _treasuryAddress The address of the treasury.
     */
    function initialize(address _sttaraToken, address _dposContract, address _apyOracle, address _treasuryAddress)
        public
        initializer
    {
        if (
            _sttaraToken == address(0) || _dposContract == address(0) || _apyOracle == address(0)
                || _treasuryAddress == address(0)
        ) revert ZeroAddress();

        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        __Ownable_init(msg.sender);
        stTaraToken = IstTara(_sttaraToken);
        dposContract = DposInterface(_dposContract);
        apyOracle = IApyOracle(_apyOracle);
        treasuryAddress = _treasuryAddress;
        epochDuration = 1000;
        maxValidatorStakeCapacity = 80000000 ether;
        minStakeAmount = 1000 ether;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

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
    function isValidatorRegistered(address validator) public view returns (bool) {
        return protocolTotalStakeAtValidator[validator] > 0;
    }

    /**
     * @inheritdoc ILara
     */
    function setCommissionDiscounts(address staker, uint32 discount) public onlyOwner {
        commissionDiscounts[staker] = discount;
        emit CommissionDiscountUpdated(staker, discount);
    }

    /**
     * @inheritdoc ILara
     */
    function setEpochDuration(uint256 _epochDuration) public onlyOwner {
        uint256 oldEpochDuration = epochDuration;
        epochDuration = _epochDuration;
        emit EpochDurationUpdated(oldEpochDuration, _epochDuration);
    }

    /**
     * @inheritdoc ILara
     */
    function setCommission(uint256 _commission) public onlyOwner {
        commission = _commission;
        emit CommissionChanged(_commission);
    }

    /**
     * @inheritdoc ILara
     */
    function setTreasuryAddress(address _treasuryAddress) public onlyOwner {
        require(_treasuryAddress != address(0), "Zero address");
        treasuryAddress = _treasuryAddress;
        emit TreasuryChanged(_treasuryAddress);
    }

    /**
     * @inheritdoc ILara
     */
    function setMaxValidatorStakeCapacity(uint256 _maxValidatorStakeCapacity) external onlyOwner {
        uint256 oldCapacity = maxValidatorStakeCapacity;
        maxValidatorStakeCapacity = _maxValidatorStakeCapacity;
        emit MaxValidatorStakeCapacityUpdated(oldCapacity, _maxValidatorStakeCapacity);
    }

    /**
     * @inheritdoc ILara
     */
    function setMinStakeAmount(uint256 _minStakeAmount) external onlyOwner {
        uint256 oldMinStakeAmount = minStakeAmount;
        minStakeAmount = _minStakeAmount;
        emit MinStakeAmountUpdated(oldMinStakeAmount, _minStakeAmount);
    }

    /**
     * @inheritdoc ILara
     */
    function stake(uint256 amount) public payable nonReentrant returns (uint256) {
        // Base checks
        if (amount < minStakeAmount) {
            revert StakeAmountTooLow(amount, minStakeAmount);
        }
        if (msg.value != amount) revert StakeValueIncorrect(msg.value, amount);

        // Delegate to validators
        uint256 remainingAmount = _delegateToValidators(address(this).balance);
        // Sync delegations
        _syncDelegations();

        // Ensure the remainingAmount is not greater than the user's staked amount
        if (remainingAmount > amount) {
            revert("LARA: Remaining amount is greater than staked amount");
        }

        if (protocolStartTimestamp == 0) {
            protocolStartTimestamp = block.timestamp;
        }
        // Mint stTARA tokens to user
        try stTaraToken.mint(msg.sender, amount - remainingAmount) {
            if (remainingAmount > 0) {
                (bool success,) = address(msg.sender).call{value: remainingAmount}("");
                if (!success) {
                    revert("LARA: Failed to send remaining amount to user");
                }
            }
            emit Staked(msg.sender, amount - remainingAmount);
            return remainingAmount;
        } catch Error(string memory reason) {
            revert(reason);
        }
    }

    /**
     * @inheritdoc ILara
     */
    function compound(uint256 amount) public nonReentrant onlyOwner {
        _delegateToValidators(amount);
    }

    /**
     * @inheritdoc ILara
     */
    function snapshot() external nonReentrant returns (uint256 id) {
        if (lastSnapshotBlock != 0 && block.number < lastSnapshotBlock + epochDuration) {
            revert EpochDurationNotMet(lastSnapshotBlock, block.number, epochDuration);
        }

        // Get total delegation
        uint256 totalEpochDelegation = 0;
        try dposContract.getTotalDelegation(address(this)) returns (uint256 totalDelegation) {
            totalEpochDelegation = totalDelegation;
        } catch Error(string memory reason) {
            revert(reason);
        }

        if (protocolStartTimestamp == 0) {
            protocolStartTimestamp = block.timestamp;
        }
        if (totalEpochDelegation == 0) {
            revert NoDelegation();
        }
        uint256 balanceBefore = address(this).balance;

        // Claim all rewards
        try dposContract.claimAllRewards() {
            // do nothing
        } catch Error(string memory reason) {
            revert RewardClaimFailed(reason);
        }
        uint256 balanceAfter = address(this).balance;
        uint256 rewards = balanceAfter - balanceBefore;

        emit AllRewardsClaimed(rewards);

        // Calculate epoch commission
        uint256 epochCommission = (rewards * commission) / 100;
        uint256 distributableRewards = rewards - epochCommission;

        // make stTARA snapshot
        uint256 stTaraSnapshotId = stTaraToken.snapshot();

        rewardsPerSnapshot[stTaraSnapshotId] = distributableRewards;

        lastSnapshotBlock = block.number;
        lastSnapshotId = stTaraSnapshotId;

        (bool success,) = treasuryAddress.call{value: epochCommission}("");
        if (!success) revert TransferFailed(address(this), treasuryAddress, epochCommission);
        emit CommissionWithdrawn(treasuryAddress, epochCommission);
        emit SnapshotTaken(
            stTaraSnapshotId, totalEpochDelegation, distributableRewards, lastSnapshotBlock + epochDuration
        );
        return (stTaraSnapshotId);
    }

    /**
     * @inheritdoc ILara
     */
    function distributeRewardsForSnapshot(address staker, uint256 snapshotId) external {
        if (staker == address(0)) revert ZeroAddress();
        if (snapshotId == 0 || rewardsPerSnapshot[snapshotId] == 0) revert SnapshotNotFound(snapshotId);
        if (stakerSnapshotClaimed[staker][snapshotId]) revert SnapshotAlreadyClaimed(snapshotId, staker);

        // Calculate rewards for snapshot for staker
        uint256 stTARASupply = stTaraToken.totalSupplyAt(snapshotId);
        uint256 distributableRewards = rewardsPerSnapshot[snapshotId];
        uint256 delegatorBalance = stTaraToken.cumulativeBalanceOfAt(staker, snapshotId);

        if (delegatorBalance == 0 || distributableRewards == 0) {
            return;
        }
        uint256 slice = (delegatorBalance * 1e18) / stTARASupply;
        uint256 generalPart = slice * distributableRewards / 1e18;
        uint256 commissionPart = (generalPart * commissionDiscounts[staker]) / 100;
        uint256 delegatorReward = generalPart + commissionPart;
        if (delegatorReward == 0) {
            return;
        }
        // Mint stTARA tokens to staker
        try stTaraToken.mint(staker, delegatorReward) {
            stakerSnapshotClaimed[staker][snapshotId] = true;
            emit RewardsClaimedForSnapshot(snapshotId, staker, delegatorReward, delegatorBalance);
            return;
        } catch Error(string memory reason) {
            revert(reason);
        }
    }

    /**
     * @inheritdoc ILara
     */
    function rebalance() public nonReentrant {
        if (block.number < lastRebalance + epochDuration) {
            revert EpochDurationNotMet(lastRebalance, block.number, epochDuration);
        }
        _syncDelegations();
        IApyOracle.TentativeDelegation[] memory delegationList = _buildCurrentDelegationArray();
        // Get the rebalance list from the oracle
        try apyOracle.getRebalanceList(delegationList) returns (IApyOracle.TentativeReDelegation[] memory rebalanceList)
        {
            // Go through the rebalance list and redelegate
            for (uint256 i = 0; i < rebalanceList.length; i++) {
                _reDelegate(
                    rebalanceList[i].from, rebalanceList[i].to, rebalanceList[i].amount, rebalanceList[i].toRating
                );
            }
            lastRebalance = block.number;
        } catch Error(string memory reason) {
            revert(reason);
        }
    }

    /**
     * @inheritdoc ILara
     */
    function confirmUndelegate(uint64 id) public {
        if (undelegations[msg.sender][id].undelegation_id == 0) {
            revert UndelegationNotFound(msg.sender, id);
        }

        address validator = undelegations[msg.sender][id].undelegation_data.validator;
        undelegated[msg.sender] = undelegated[msg.sender] - undelegations[msg.sender][id].undelegation_data.stake;
        delete undelegations[msg.sender][id];
        uint256 balanceBefore = address(this).balance;

        (bool success,) =
            address(dposContract).call(abi.encodeWithSignature("confirmUndelegateV2(address,uint64)", validator, id));
        if (!success) {
            revert ConfirmUndelegationFailed(msg.sender, validator, id, "DPOS contract call failed");
        }

        uint256 balanceAfter = address(this).balance;
        if (balanceAfter - balanceBefore == 0) {
            return;
        } else {}
        // we need to send the rewards to the user
        (bool s,) = msg.sender.call{value: balanceAfter - balanceBefore}("");
        if (!s) revert("LARA: Failed to send undelegation to user");
        emit TaraSent(msg.sender, balanceAfter - balanceBefore);
    }

    /**
     * @inheritdoc ILara
     */
    function batchConfirmUndelegate(uint64[] calldata ids) external {
        for (uint256 i = 0; i < ids.length; i++) {
            confirmUndelegate(ids[i]);
        }
    }

    /**
     * @inheritdoc ILara
     */
    function cancelUndelegate(uint64 id) public {
        if (undelegations[msg.sender][id].undelegation_id == 0) {
            revert UndelegationNotFound(msg.sender, id);
        }
        uint256 amount = undelegations[msg.sender][id].undelegation_data.stake;
        address validator = undelegations[msg.sender][id].undelegation_data.validator;

        protocolTotalStakeAtValidator[validator] = protocolTotalStakeAtValidator[validator] + amount;
        undelegated[msg.sender] = undelegated[msg.sender] - amount;
        delete undelegations[msg.sender][id];

        (bool success,) =
            address(dposContract).call(abi.encodeWithSignature("cancelUndelegateV2(address,uint64)", validator, id));
        if (!success) {
            revert CancelUndelegationFailed(msg.sender, validator, id, "DPOS contract call failed");
        }

        try stTaraToken.mint(msg.sender, amount) {}
        catch Error(string memory reason) {
            revert(reason);
        }
        emit UndelegationCancelled(msg.sender, validator, id, amount);
    }

    /**
     * @inheritdoc ILara
     */
    function batchCancelUndelegate(uint64[] calldata ids) external {
        for (uint256 i = 0; i < ids.length; i++) {
            cancelUndelegate(ids[i]);
        }
    }

    /**
     * @inheritdoc ILara
     */
    function requestUndelegate(uint256 amount) public nonReentrant returns (uint64[] memory undelegation_ids) {
        require(stTaraToken.allowance(msg.sender, address(this)) >= amount, "Amount not approved for unstaking");
        // register the undelegation request
        try stTaraToken.transferFrom(msg.sender, address(this), amount) {
            try stTaraToken.burn(address(this), amount) {
                // check if the amount is approved in stTara for the protocol
                // get the stTARA tokens and burn them
                uint256 remainingAmount = amount;
                uint256 undelegatedTotal = 0;
                _syncDelegations();
                address[] memory validatorsWithDelegation = _findValidatorsWithDelegation(amount);
                undelegation_ids = new uint64[](validatorsWithDelegation.length);
                uint256 totalRewards = 0;
                for (uint16 i = 0; i < validatorsWithDelegation.length; i++) {
                    uint256 toUndelegate = 0;
                    if (protocolTotalStakeAtValidator[validatorsWithDelegation[i]] == 0) {
                        continue;
                    }

                    if (protocolTotalStakeAtValidator[validatorsWithDelegation[i]] < remainingAmount) {
                        toUndelegate = protocolTotalStakeAtValidator[validatorsWithDelegation[i]];
                    } else {
                        toUndelegate = remainingAmount;
                    }
                    uint256 balanceBefore = address(this).balance;
                    uint64 undelegationId;
                    try dposContract.undelegateV2(validatorsWithDelegation[i], toUndelegate) returns (uint64 id) {
                        undelegationId = id;
                    } catch {
                        revert UndelegationFailed(validatorsWithDelegation[i], msg.sender, toUndelegate);
                    }
                    undelegatedTotal += toUndelegate;
                    remainingAmount -= toUndelegate;
                    uint256 balanceAfter = address(this).balance;
                    totalRewards += balanceAfter - balanceBefore;
                    undelegations[msg.sender][undelegationId] =
                        dposContract.getUndelegationV2(address(this), validatorsWithDelegation[i], undelegationId);
                    undelegation_ids[i] = undelegationId;
                    emit Undelegated(undelegationId, msg.sender, validatorsWithDelegation[i], toUndelegate);
                    if (undelegatedTotal == amount) break;
                }
                if (undelegatedTotal != amount) {
                    revert UndelegationsNotMatching(undelegatedTotal, amount);
                }
                undelegated[msg.sender] += undelegatedTotal;
                if (totalRewards > 0) {
                    (bool success,) = msg.sender.call{value: totalRewards}("");
                    if (!success) {
                        revert("LARA: Failed to send rewards to user");
                    }
                    emit TaraSent(msg.sender, totalRewards);
                }
                _syncDelegations();
                return undelegation_ids;
            } catch Error(string memory reason) {
                revert(reason);
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
    function _reDelegate(address from, address to, uint256 amount, uint256 rating) internal {
        require(protocolTotalStakeAtValidator[from] >= amount, "LARA: Amount exceeds the total stake at the validator");
        require(amount <= maxValidatorStakeCapacity, "LARA: Amount exceeds max stake of validators in protocol");
        require(
            protocolTotalStakeAtValidator[to] + amount <= maxValidatorStakeCapacity,
            "LARA: Redelegation to new validator exceeds max stake"
        );
        uint256 balanceBefore = address(this).balance;

        try dposContract.reDelegate(from, to, amount) {
            // do nothing
        } catch Error(string memory reason) {
            revert RedelegationFailed(from, to, amount, reason);
        }

        uint256 balanceAfter = address(this).balance;
        // send this amount to the treasury as it is minimal
        (bool s,) = treasuryAddress.call{value: balanceAfter - balanceBefore}("");
        if (!s) revert("LARA: Failed to send commission to treasury");
        emit RedelegationRewardsClaimed(balanceAfter - balanceBefore, from);
        emit TaraSent(treasuryAddress, balanceAfter - balanceBefore);

        protocolTotalStakeAtValidator[from] = protocolTotalStakeAtValidator[from] - amount;
        if (protocolTotalStakeAtValidator[from] == 0) {
            protocolValidatorRatingAtDelegation[from] = 0;
        }
        protocolTotalStakeAtValidator[to] = protocolTotalStakeAtValidator[to] + amount;
        protocolValidatorRatingAtDelegation[to] = rating;
    }

    /**
     * @notice Delegate function
     * In the delegate function, the caller can start the staking of any remaining balance in Lara towards the native DPOS contract.
     * @notice Anyone can call, it will always delegate the given amount from Lara's balance
     * @param amount the amount to delegate
     * @return remainingAmount the remaining amount that could not be delegated
     */
    function _delegateToValidators(uint256 amount) internal returns (uint256 remainingAmount) {
        require(address(this).balance >= amount, "Not enough balance");
        uint256 delegatedAmount = 0;
        IApyOracle.TentativeDelegation[] memory nodesList = _getValidatorsForAmount(amount);
        if (nodesList.length == 0) {
            revert("No nodes available for delegation");
        }
        for (uint256 i = 0; i < nodesList.length; i++) {
            if (delegatedAmount == amount) break;
            try dposContract.delegate{value: nodesList[i].amount}(nodesList[i].validator) {
                // do nothing
            } catch Error(string memory reason) {
                revert DelegationFailed(nodesList[i].validator, msg.sender, nodesList[i].amount, reason);
            }

            delegatedAmount += nodesList[i].amount;
            protocolValidatorRatingAtDelegation[nodesList[i].validator] = nodesList[i].rating;
        }
        return amount - delegatedAmount;
    }

    /**
     * Fetches the validators for the given amount
     * @param amount the amount to fetch the validators for
     * @return the validators for the given amount
     */
    function _getValidatorsForAmount(uint256 amount) internal returns (IApyOracle.TentativeDelegation[] memory) {
        try apyOracle.getNodesForDelegation(amount) returns (IApyOracle.TentativeDelegation[] memory nodesList) {
            if (nodesList.length == 0) {
                revert("No nodes available for delegation");
            }
            return nodesList;
        } catch Error(string memory reason) {
            revert(reason);
        }
    }

    /**
     * @notice method to find the validators to delegate to
     * @param amount the amount to delegate
     * @return an array of validators to delegate amount of TARA to
     */
    function _findValidatorsWithDelegation(uint256 amount) internal view returns (address[] memory) {
        uint8 i = 0;
        uint256 stakeRemaining = 0;
        DposInterface.DelegationData[] memory delegations = _getDelegationsFromDpos();
        for (; i < delegations.length; i++) {
            require(
                delegations[i].delegation.stake == protocolTotalStakeAtValidator[delegations[i].account],
                "Delegation is not matching DPOS"
            );
            if (delegations[i].delegation.stake == 0) {
                continue;
            }
            stakeRemaining += delegations[i].delegation.stake;
            if (stakeRemaining >= amount) {
                break;
            }
        }
        address[] memory result = new address[](i + 1);
        for (uint8 j = 0; j < i + 1; j++) {
            result[j] = delegations[j].account;
        }
        return result;
    }

    /**
     * @notice method to build the current delegation array
     * Collects the current delegation data from the protocol and builds an array of TentativeDelegation structs
     */
    function _buildCurrentDelegationArray() internal view returns (IApyOracle.TentativeDelegation[] memory) {
        DposInterface.DelegationData[] memory delegations = _getDelegationsFromDpos();
        IApyOracle.TentativeDelegation[] memory result = new IApyOracle.TentativeDelegation[](delegations.length);
        for (uint256 i = 0; i < delegations.length; i++) {
            result[i] = IApyOracle.TentativeDelegation(
                delegations[i].account,
                delegations[i].delegation.stake,
                protocolValidatorRatingAtDelegation[delegations[i].account]
            );
        }
        return result;
    }

    /**
     * @notice method to get the delegations from the DPOS contract
     * @return the delegations from the DPOS contract
     */
    function _getDelegationsFromDpos() internal view returns (DposInterface.DelegationData[] memory) {
        uint32 batch = 0;
        try dposContract.getDelegations(address(this), batch) returns (
            DposInterface.DelegationData[] memory delegations, bool
        ) {
            return delegations;
        } catch Error(string memory reason) {
            revert(reason);
        }
    }

    /**
     * @notice method to sync the delegations from the DPOS contract
     */
    function _syncDelegations() internal {
        DposInterface.DelegationData[] memory delegations = _getDelegationsFromDpos();
        for (uint256 i = 0; i < delegations.length; i++) {
            protocolTotalStakeAtValidator[delegations[i].account] = delegations[i].delegation.stake;

            emit DelegationSynced(delegations[i].account, delegations[i].delegation.stake);

            if (delegations[i].delegation.stake == 0) {
                protocolValidatorRatingAtDelegation[delegations[i].account] = 0;
                emit ValidatorRatingReset(delegations[i].account);
            }
        }
    }
}
