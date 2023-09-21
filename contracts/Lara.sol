// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IstTara.sol";
import "./interfaces/IDPOS.sol";
import "./interfaces/IApyOracle.sol";
import "./interfaces/INodeContinuityOracle.sol";

contract Lara is Ownable {
    // Errors
    error StakeAmountTooLow(uint256 amount, uint256 minAmount);
    error StakeValueTooLow(uint256 sentAmount, uint256 targetAmount);

    // Events
    event Staked(address indexed user, uint256 amount);

    // State variables

    uint256 public maxValidatorStakeCapacity = 80000000 ether;

    uint256 public minStakeAmount = 1000 ether;

    IstTara public sttaraToken;

    DposInterface public dposContract;

    IApyOracle public apyOracle;

    INodeContinuityOracle public continuityOracle;

    struct IndividualDelegation {
        address user;
        uint256 amount;
        uint256 timestamp;
    }

    struct ValidatorDelegation {
        address validator;
        uint256 amount;
        uint256 lastClaimedTimestamp;
    }

    // enum DelegationStrategy {
    //     MAX_APY,
    //     CONTINUITY
    // }

    mapping(address => uint256) public stakedAmounts;

    mapping(address => mapping(address => uint256))
        public stakedAmountsByValidator;

    mapping(address => IndividualDelegation[]) public individualDelegations;

    mapping(address => ValidatorDelegation[]) public validatorDelegations;

    constructor(
        address _sttaraToken,
        address _dposContract,
        address _apyOracle,
        address _continuityOracle
    ) {
        sttaraToken = IstTara(_sttaraToken);
        dposContract = DposInterface(_dposContract);
        apyOracle = IApyOracle(_apyOracle);
        continuityOracle = INodeContinuityOracle(_continuityOracle);
    }

    function stake(uint256 amount) external payable {
        if(amount < minStakeAmount)
            revert StakeAmountTooLow(amount, minStakeAmount);
        if(msg.value < amount)
            revert StakeValueTooLow(msg.value, amount);

        // Delegate to the highest APY validators and return if there is any remaining amount
        uint256 remainingAmount = delegateToValidators(amount);
        if(remainingAmount != 0) {
            payable(msg.sender).transfer(remainingAmount);
            amount -= remainingAmount;
        }
        // Mint stTARA tokens to user
        sttaraToken.mint{value: msg.value}();
        sttaraToken.transfer(msg.sender, amount);

        // Update stakedAmounts mapping
        stakedAmounts[msg.sender] += amount;

        emit Staked(msg.sender, amount);
    }

    function delegateToValidators(
        uint256 amount
    ) internal returns (uint256 remainingAmount) {
        uint256 nodeCount = apyOracle.getNodeCount();
        IApyOracle.NodeData[] memory nodeData = new IApyOracle.NodeData[](
            nodeCount
        );
        address[] memory nodesList = apyOracle.getNodesList();
        for (uint256 i = 0; i < nodeCount; i++) {
            nodeData[i] = apyOracle.getNodeData(nodesList[i]);
            DposInterface.ValidatorBasicInfo memory validatorInfo = dposContract
                .getValidator(nodeData[i].account);
            uint256 nodeCapacity = maxValidatorStakeCapacity - validatorInfo.total_stake;
            if(amount <= nodeCapacity) {
                //delegate the amount
                dposContract.delegate{value: amount}(nodeData[i].account);
                return 0;
            } else { //amount > nodeCapacity
                //delegate nodeCapacity
                dposContract.delegate{value: nodeCapacity}(nodeData[i].account); 
                amount -= nodeCapacity;
            }
        }
        // Return the remaining amount if there is no capacity in all the nodes
        return amount;
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
