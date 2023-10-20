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
                if (validatorDelegations[nodesList[i].validator].length == 0) {
                    firstDelegationTimestampToValidator[
                        nodesList[i].validator
                    ] = block.timestamp;
                }
                validatorDelegations[nodesList[i].validator].push(
                    ValidatorDelegation({
                        delegator: msg.sender,
                        amount: nodesList[i].amount,
                        timestamp: block.timestamp
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

    function _accrueRewardsForValidator(address validator) internal {
        // get the delegations for the validator
        ValidatorDelegation[] memory delegations = getValidatorDelegations(
            validator
        );

        if (delegations.length == 0) return;

        uint256 balanceBefore = address(this).balance;
        uint256 totalClaimed = 0;

        // claim the rewards for the validator
        try dposContract.claimRewards(validator) {
            // get the rewards for the validator
            totalClaimed = address(this).balance - balanceBefore;
            // mint the rewards to the validator
            if (totalClaimed == 0) revert("No rewards to claim");
            delete firstDelegationTimestampToValidator[validator];
        } catch {
            revert RewardClaimFailed(validator);
        }

        // calculate the proportional rewards for each delegator
        for (uint256 i = 0; i < delegations.length; i++) {
            // get the delegation amount
            uint256 delegationAmount = delegations[i].amount;
            // get the delegation timestamp
            uint256 delegationTimestamp = delegations[i].timestamp;

            uint256 epochDuration = block.timestamp -
                firstDelegationTimestampToValidator[validator];
            // calculate the proportional rewards
            uint256 proportionalRewards = (((delegationAmount * totalClaimed) /
                protocolTotalStakeAtValidator[validator]) *
                (block.timestamp - delegationTimestamp)) / epochDuration;

            // add entry to the delegator's rewards
            if (proportionalRewards == 0) continue;
            rewards[delegations[i].delegator].push(
                Reward({
                    validator: validator,
                    amount: proportionalRewards,
                    length: block.timestamp - delegationTimestamp
                })
            );
            emit RewardsAccrued(
                delegations[i].delegator,
                validator,
                proportionalRewards,
                block.timestamp - delegationTimestamp
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

    function setMaxValdiatorStakeCapacity(
        uint256 _maxValidatorStakeCapacity
    ) external onlyOwner {
        maxValidatorStakeCapacity = _maxValidatorStakeCapacity;
    }

    function setMinStakeAmount(uint256 _minStakeAmount) external onlyOwner {
        minStakeAmount = _minStakeAmount;
    }
}
