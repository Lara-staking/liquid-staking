// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IstTara} from "./interfaces/IstTara.sol";
import {DposInterface} from "./interfaces/IDPOS.sol";
import {IApyOracle} from "./interfaces/IApyOracle.sol";
import {ILara} from "./interfaces/ILara.sol";
import {DelegationFailed, RewardClaimFailed} from "./errors/DelegationErrors.sol";
import {StakeAmountTooLow, StakeValueTooLow} from "./errors/LaraErrors.sol";

contract Lara is ILara, Ownable {
    // State variables

    // Reference timestamp for computing epoch number
    uint256 public startTimestamp;

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

    // Proportional Rewards = (Delegated amount/Total amount) *
    //    (Delegation Duration / Total Duration in the Epoch) *
    //      Total Rewards Claimed in the Epoch
    mapping(address => uint256) private stakedAmounts;
    mapping(address => IndividualDelegation[]) private individualDelegations;
    mapping(address => Reward[]) private rewards;
    mapping(address => ValidatorDelegation[]) private validatorDelegations;
    mapping(address => uint256) private protocolTotalStakeAtValidator;
    mapping(address => uint256) private firstDelegationTimestampToValidator;

    constructor(
        address _sttaraToken,
        address _dposContract,
        address _apyOracle
    ) {
        stTaraToken = IstTara(_sttaraToken);
        dposContract = DposInterface(_dposContract);
        apyOracle = IApyOracle(_apyOracle);
        startTimestamp = block.timestamp;
    }

    fallback() external payable {}

    receive() external payable {}

    /**
     * @dev getter for stakedAmounts
     */
    function getStakedAmount(address user) public view returns (uint256) {
        return stakedAmounts[user];
    }

    /**
     * @dev getter for firstDelegationToValidator
     */
    function getFirstDelegationToValidator(
        address validator
    ) public view returns (uint256) {
        return firstDelegationTimestampToValidator[validator];
    }

    /**
     * @dev getter for individualDelegations
     */
    function getIndividualDelegations(
        address user
    ) public view returns (IndividualDelegation[] memory) {
        return individualDelegations[user];
    }

    /**
     * @dev getter for validatorDelegations
     */
    function getValidatorDelegations(
        address validator
    ) public view returns (ValidatorDelegation[] memory) {
        return validatorDelegations[validator];
    }

    /**
     * @dev getter for rewards
     */
    function getRewards(address user) public view returns (Reward[] memory) {
        return rewards[user];
    }

    /**
     * @dev getter for protocolTotalStakeAtValdiator
     */
    function getProtocolTotalStakeAtValdiator(
        address validator
    ) public view returns (uint256) {
        return protocolTotalStakeAtValidator[validator];
    }

    function stake(uint256 amount) external payable returns (uint256) {
        // Check if the user has delegation already
        if (amount < minStakeAmount)
            revert StakeAmountTooLow(amount, minStakeAmount);
        if (msg.value < amount) revert StakeValueTooLow(msg.value, amount);

        // Delegate to the highest APY validators and return if there is any remaining amount
        uint256 remainingAmount = delegateToValidators(amount);
        if (remainingAmount != 0) {
            payable(msg.sender).transfer(remainingAmount);
            amount -= remainingAmount;
        }
        if (amount == 0)
            revert("No amount could be staked. Validators are full.");
        stakedAmounts[msg.sender] += amount;

        // Mint stTARA tokens to user
        stTaraToken.mint(msg.sender, amount);

        emit Staked(msg.sender, amount);
        return remainingAmount;
    }

    function delegateToValidators(
        uint256 amount
    ) internal returns (uint256 remainingAmount) {
        uint256 delegatedAmount = 0;
        IApyOracle.TentativeDelegation[] memory nodesList = apyOracle
            .getNodesForDelegation(amount);
        for (uint256 i = 0; i < nodesList.length; i++) {
            //delegate the amount
            try
                dposContract.delegate{value: nodesList[i].amount}(
                    nodesList[i].validator
                )
            {
                delegatedAmount += nodesList[i].amount;
                individualDelegations[msg.sender].push(
                    IndividualDelegation({
                        validator: nodesList[i].validator,
                        amount: nodesList[i].amount,
                        timestamp: block.timestamp
                    })
                );
                if (
                    validatorDelegations[nodesList[i].validator].length == 0 ||
                    firstDelegationTimestampToValidator[
                        nodesList[i].validator
                    ] ==
                    0
                ) {
                    firstDelegationTimestampToValidator[
                        nodesList[i].validator
                    ] = block.timestamp;
                }
                validatorDelegations[nodesList[i].validator].push(
                    ValidatorDelegation({
                        delegator: msg.sender,
                        amount: nodesList[i].amount,
                        delegationTimestamp: block.timestamp,
                        lastClaimedTimestamp: block.timestamp
                    })
                );
                protocolTotalStakeAtValidator[
                    nodesList[i].validator
                ] += nodesList[i].amount;
                emit Delegated(
                    msg.sender,
                    nodesList[i].validator,
                    nodesList[i].amount,
                    block.timestamp
                );
            } catch {
                revert DelegationFailed(
                    nodesList[i].validator,
                    msg.sender,
                    amount,
                    ""
                );
            }
        }
        // Return the remaining amount if there is no capacity in all the nodes
        return amount - delegatedAmount;
    }

    function delegateToValidatorsForAddress(
        uint256 amount,
        address delegator
    ) internal returns (uint256 remainingAmount) {
        uint256 delegatedAmount = 0;
        IApyOracle.TentativeDelegation[] memory nodesList = apyOracle
            .getNodesForDelegation(amount);
        for (uint256 i = 0; i < nodesList.length; i++) {
            //delegate the amount
            try
                dposContract.delegate{value: nodesList[i].amount}(
                    nodesList[i].validator
                )
            {
                delegatedAmount += nodesList[i].amount;
                individualDelegations[delegator].push(
                    IndividualDelegation({
                        validator: nodesList[i].validator,
                        amount: nodesList[i].amount,
                        timestamp: block.timestamp
                    })
                );
                if (
                    validatorDelegations[nodesList[i].validator].length == 0 ||
                    firstDelegationTimestampToValidator[
                        nodesList[i].validator
                    ] ==
                    0
                ) {
                    firstDelegationTimestampToValidator[
                        nodesList[i].validator
                    ] = block.timestamp;
                }
                validatorDelegations[nodesList[i].validator].push(
                    ValidatorDelegation({
                        delegator: delegator,
                        amount: nodesList[i].amount,
                        delegationTimestamp: block.timestamp,
                        lastClaimedTimestamp: block.timestamp
                    })
                );
                protocolTotalStakeAtValidator[
                    nodesList[i].validator
                ] += nodesList[i].amount;
                emit Delegated(
                    delegator,
                    nodesList[i].validator,
                    nodesList[i].amount,
                    firstDelegationTimestampToValidator[nodesList[i].validator]
                );
            } catch {
                revert DelegationFailed(
                    nodesList[i].validator,
                    delegator,
                    amount,
                    ""
                );
            }
        }
        // Return the remaining amount if there is no capacity in all the nodes
        return amount - delegatedAmount;
    }

    function _accrueRewardsForValidator(address validator) internal {
        // get the delegations for the validator
        ValidatorDelegation[] memory delegations = getValidatorDelegations(
            validator
        );

        if (delegations.length == 0) return;

        uint256 balanceBefore = address(this).balance;
        uint256 totalClaimed = 0;
        uint256 firstDelegationTimestamp = 0;

        // claim the rewards for the validator
        try dposContract.claimRewards(validator) {
            // get the rewards for the validator
            totalClaimed = address(this).balance - balanceBefore;
            // mint the rewards to the validator
            if (totalClaimed == 0) revert("No rewards to claim");
            firstDelegationTimestamp = firstDelegationTimestampToValidator[
                validator
            ];
            firstDelegationTimestampToValidator[validator] = block.timestamp;
        } catch {
            revert RewardClaimFailed(validator);
        }

        // calculate the proportional rewards for each delegator
        for (uint256 i = 0; i < delegations.length; i++) {
            // get the delegation amount
            uint256 delegationAmount = delegations[i].amount;
            // get the delegation timestamp
            uint256 lastClaimedTimestamp = delegations[i].lastClaimedTimestamp;
            validatorDelegations[validator][i].lastClaimedTimestamp = block
                .timestamp;

            uint256 epochDuration = block.timestamp - firstDelegationTimestamp;
            if (epochDuration == 0) continue;
            // calculate the proportional rewards
            uint256 proportionalRewards = (((delegationAmount * totalClaimed) /
                protocolTotalStakeAtValidator[validator]) *
                (block.timestamp - lastClaimedTimestamp)) / epochDuration;

            // add entry to the delegator's rewards
            if (proportionalRewards == 0) continue;
            rewards[delegations[i].delegator].push(
                Reward({
                    validator: validator,
                    amount: proportionalRewards,
                    length: block.timestamp - lastClaimedTimestamp
                })
            );
            emit RewardsAccrued(
                delegations[i].delegator,
                validator,
                proportionalRewards,
                block.timestamp - lastClaimedTimestamp
            );
        }
    }

    function accrueRewardsForDelegator(address delegator) public {
        // First check if there's a delegation from delegator at validator
        IndividualDelegation[] memory delegations = getIndividualDelegations(
            delegator
        );

        if (delegations.length == 0) return;
        // Claim the rewards
        for (uint256 i = 0; i < delegations.length; i++) {
            _accrueRewardsForValidator(delegations[i].validator);
        }
    }

    function claimRewards(address delegator) external {
        accrueRewardsForDelegator(delegator);
        // Get the rewards for the user
        Reward[] memory delegatorRewards = getRewards(delegator);
        // Iterate through the rewards of the user, remove them from the rewards mapping and send them to the user
        for (uint256 i = 0; i < delegatorRewards.length; i++) {
            uint256 amount = delegatorRewards[i].amount;
            uint256 length = delegatorRewards[i].length;
            address validator = delegatorRewards[i].validator;
            delete rewards[delegator][i];
            payable(delegator).transfer(amount);
            emit RewardsClaimed(delegator, validator, length, amount);
        }
    }

    function compound(address delegator) external onlyOwner {
        accrueRewardsForDelegator(delegator);
        // Get the rewards for the user
        Reward[] memory delegatorRewards = getRewards(delegator);
        // Iterate through the rewards of the user, remove them from the rewards mapping and send them to the user
        for (uint256 i = 0; i < delegatorRewards.length; i++) {
            uint256 amount = delegatorRewards[i].amount;
            delete rewards[delegator][i];
            // Delegate to the highest APY validators and return if there is any remaining amount
            uint256 remainingAmount = delegateToValidatorsForAddress(
                amount,
                delegator
            );
            if (remainingAmount != 0) {
                amount -= remainingAmount;
            }
            if (amount == 0)
                revert("No amount could be staked. Validators are full.");
            stakedAmounts[delegator] += amount;

            // Mint stTARA tokens to user
            stTaraToken.mint(delegator, amount);

            emit Staked(delegator, amount);
        }
    }

    function unstake(uint256 amount) public override {
        // check if the amount is approved in stTara for the protocol
        require(
            stTaraToken.allowance(msg.sender, address(this)) >= amount,
            "Amount not approved for unstaking"
        );
        // undelegate the amount on behalf of the user
        uint256 undelegated = 0;
        IndividualDelegation[] memory delegations = getIndividualDelegations(
            msg.sender
        );
        require(delegations.length > 0, "No delegations found for the user");
        for (uint16 i = 0; i < delegations.length; i++) {
            if (undelegated >= amount) break;
            if (delegations[i].amount == 0) continue;
            uint256 delegated = delegations[i].amount;
            uint256 toUndelegate = 0;
            if (delegated > amount) {
                toUndelegate = amount;
            } else {
                toUndelegate = delegated;
            }
            uint256 balanceBefore = address(this).balance;
            try
                dposContract.undelegate(delegations[i].validator, toUndelegate)
            {
                undelegated += toUndelegate;
                protocolTotalStakeAtValidator[
                    delegations[i].validator
                ] -= toUndelegate;
                emit Undelegated(msg.sender, delegations[i].validator, amount);
            } catch {
                revert("Undelegation failed");
            }
            protocolTotalStakeAtValidator[
                delegations[i].validator
            ] -= toUndelegate;
            uint256 totalClaimed = address(this).balance - balanceBefore;
            try stTaraToken.transferFrom(msg.sender, address(this), amount) {
                try stTaraToken.burn(address(this), amount) {
                    payable(msg.sender).transfer(totalClaimed);
                } catch {
                    revert("Burn failed");
                }
            } catch {
                revert("TransferFrom failed");
            }
        }
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
