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

    uint256 public lastSnapshot;
    uint256 public lastRebalance;

    // Duration of an epoch in seconds, initially 1000 blocks
    uint256 public epochDuration = 1000;

    // Maximum staking capacity for a validator
    uint256 public maxValidatorStakeCapacity = 80000000 ether;

    // Minimum amount allowed for staking
    uint256 public minStakeAmount = 1000 ether;

    // State variable for storing the last epoch's total delegated amount
    uint256 public totalDelegated = 0;

    uint256 public commission = 0;

    address public treasuryAddress = address(0);

    // List of delegators of the protocol
    address[] public delegators;

    // List of validators of the protocol
    address[] public validators;

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
     * @notice The tokens are DELEGATED INSTANTLY.
     * @param amount the amount to stake
     */
    function stake(uint256 amount) public payable returns (uint256) {
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
        uint256 remainingAmount = delegateToValidators(address(this).balance);

        if (protocolStartTimestamp == 0) {
            protocolStartTimestamp = block.timestamp;
        }
        // Mint stTARA tokens to user
        try stTaraToken.mint(msg.sender, amount - remainingAmount) {
            if (remainingAmount > 0) {
                (bool success, ) = address(msg.sender).call{
                    value: remainingAmount
                }("");
                if (!success)
                    revert("LARA: Failed to send remaining amount to user");
            }
            emit Staked(msg.sender, amount - remainingAmount);
            return remainingAmount;
        } catch Error(string memory reason) {
            revert(reason);
        }
    }

    /**
     * @notice Delegate function
     * In the delegate function, the caller can start the staking of any remaining balance in Lara towards the native DPOS contract.
     * @notice Anyone can call, it will always delegate the given amount from Lara's balance
     * @param amount the amount to delegate
     * @return remainingAmount the remaining amount that could not be delegated
     */
    function delegateToValidators(
        uint256 amount
    ) public returns (uint256 remainingAmount) {
        require(address(this).balance >= amount, "Not enough balance");
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
        totalDelegated += delegatedAmount;
        return amount - delegatedAmount;
    }

    /**
     * @notice method to create a protocol snapshot.
     * A protocol snapshot can be done once every epochDuration blocks.
     * The method will claim all rewards from the DPOS contract and distribute them to the delegators.
     */
    function snapshot() external {
        if (lastSnapshot != 0 && block.number < lastSnapshot + epochDuration) {
            revert EpochDurationNotMet(
                lastSnapshot,
                block.number,
                epochDuration
            );
        }
        uint256 totalEpochDelegation = 0;
        try dposContract.getTotalDelegation(address(this)) returns (
            uint256 totalDelegation
        ) {
            totalEpochDelegation = totalDelegation;
        } catch Error(string memory reason) {
            revert(reason);
        }
        totalDelegated = totalEpochDelegation;
        if (protocolStartTimestamp == 0) {
            protocolStartTimestamp = block.timestamp;
        }
        if (totalDelegated == 0) {
            return;
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
        for (uint256 i = 0; i < delegators.length; i++) {
            address delegator = delegators[i];
            uint256 delegatorBalance = stTaraToken.balanceOf(delegator);
            if (delegatorBalance == 0) {
                continue;
            }
            uint256 slice = Utils.calculateSlice(
                delegatorBalance,
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
        (bool success, ) = treasuryAddress.call{value: epochCommission}("");
        if (!success) revert("LARA: Failed to send commission to treasury");
        emit CommissionWithdrawn(treasuryAddress, epochCommission);

        lastSnapshot = block.number;
        emit SnapshotTaken(
            totalDelegated,
            distributableRewards,
            lastSnapshot + epochDuration
        );
    }

    /**
     * @notice Rebalance method to rebalance the protocol.
     * The method is intended to be called by anyone, at least every epochDuration blocks.
     * In this V0 there is no on-chain trigger or management function for this, will be triggered from outside.
     * The method will call the oracle to get the rebalance list and then redelegate the stake.
     */
    function rebalance() public {
        if (block.number < lastRebalance + epochDuration) {
            revert EpochDurationNotMet(
                lastRebalance,
                block.number,
                epochDuration
            );
        }
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
        (bool s, ) = treasuryAddress.call{value: balanceAfter - balanceBefore}(
            ""
        );
        if (!s) revert("LARA: Failed to send commission to treasury");
        emit RedelegationRewardsClaimed(balanceAfter - balanceBefore, from);
        emit TaraSent(treasuryAddress, balanceAfter - balanceBefore);

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
        if (balanceAfter - balanceBefore == 0) {
            return;
        } else {}
        // we need to send the rewards to the user
        (bool s, ) = msg.sender.call{value: balanceAfter - balanceBefore}("");
        if (!s) revert("LARA: Failed to send undelegation to user");
        emit TaraSent(msg.sender, balanceAfter - balanceBefore);
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
    function requestUndelegate(
        uint256 amount
    ) public returns (Utils.Undelegation[] memory undelegations) {
        require(
            stTaraToken.allowance(msg.sender, address(this)) >= amount,
            "Amount not approved for unstaking"
        );
        // register the undelegation request
        try stTaraToken.transferFrom(msg.sender, address(this), amount) {
            try stTaraToken.burn(address(this), amount) {
                // check if the amount is approved in stTara for the protocol
                // get the stTARA tokens and burn them
                uint256 remainingAmount = amount;
                uint256 undelegatedTotal = 0;
                address[]
                    memory validatorsWithDelegation = findValidatorsWithDelegation(
                        amount
                    );
                Utils.Undelegation[]
                    memory undelegationsList = new Utils.Undelegation[](
                        validatorsWithDelegation.length
                    );
                uint256 totalRewards = 0;
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
                    undelegatedTotal += toUndelegate;
                    remainingAmount -= toUndelegate;
                    uint256 balanceAfter = address(this).balance;
                    totalRewards += balanceAfter - balanceBefore;
                    protocolTotalStakeAtValidator[
                        validatorsWithDelegation[i]
                    ] -= toUndelegate;
                    if (
                        protocolTotalStakeAtValidator[
                            validatorsWithDelegation[i]
                        ] == 0
                    ) {
                        protocolValidatorRatingAtDelegation[
                            validatorsWithDelegation[i]
                        ] = 0;
                    }
                    undelegationsList[i] = Utils.Undelegation(
                        validatorsWithDelegation[i],
                        toUndelegate
                    );
                    emit Undelegated(
                        msg.sender,
                        validatorsWithDelegation[i],
                        toUndelegate
                    );
                    if (undelegatedTotal == amount) break;
                }
                require(
                    undelegatedTotal == amount,
                    "Cannot undelegate full amount"
                );
                undelegated[msg.sender] += undelegatedTotal;
                if (totalRewards > 0) {
                    (bool success, ) = msg.sender.call{value: totalRewards}("");
                    if (!success)
                        revert("LARA: Failed to send rewards to user");
                    emit TaraSent(msg.sender, totalRewards);
                }
                return undelegationsList;
            } catch Error(string memory reason) {
                revert(reason);
            }
        } catch Error(string memory reason) {
            revert(reason);
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

    /**
     * @notice method to find the validators to delegate to
     * @param amount the amount to delegate
     * @return an array of validators to delegate amount of TARA to
     */
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

    /**
     * @notice method to build the current delegation array
     * Collects the current delegation data from the protocol and builds an array of TentativeDelegation structs
     */
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
