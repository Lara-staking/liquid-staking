// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IDPOS.sol";
import "./interfaces/IApyOracle.sol";
import "./interfaces/INodeContinuityOracle.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Lara is Ownable {
    uint256 public MAX_DELEGATION = 80000000 ether;

    ERC20 public sttaraToken;
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

    struct DelegationDetail {
        address validator;
        uint256 amount;
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
        sttaraToken = ERC20(_sttaraToken);
        dposContract = DposInterface(_dposContract);
        apyOracle = IApyOracle(_apyOracle);
        continuityOracle = INodeContinuityOracle(_continuityOracle);
    }

    function setMaxStakePerValdiator(
        uint256 newMaxDelegation
    ) external onlyOwner {
        MAX_DELEGATION = newMaxDelegation;
    }

    function stake(uint256 amount) external payable {
        require(amount >= 1000 ether, "Minimum stake is 1000 TARA");
        require(msg.value >= 1000 ether, "Minimum stake is 1000 TARA");

        // Mint stTARA tokens to user

        // Update stakedAmounts mapping

        // Delegate to the highest APY validator
        DelegationDetail[]
            memory highestAPYValidators = getHighestAPYValidators(amount);
        delegateToValidators(highestAPYValidators, amount);

        emit Staked(msg.sender, amount);
    }

    function getHighestAPYValidators(
        uint256 amount
    ) internal view returns (DelegationDetail[] memory) {
        DelegationDetail[] memory validators;
        uint256 nodeCount = apyOracle.getNodeCount();
        IApyOracle.NodeData[] memory nodeData = new IApyOracle.NodeData[](
            nodeCount
        );
        address[] memory nodesList = apyOracle.getNodesList();
        for (uint256 i = 0; i < nodeCount; i++) {
            nodeData[i] = apyOracle.getNodeData(nodesList[i]);
            DposInterface.ValidatorBasicInfo memory validatorInfo = dposContract
                .getValidator(nodeData[i].account);
            if (amount < MAX_DELEGATION) {
                validators = new DelegationDetail[](1);
                validators[0] = DelegationDetail(nodeData[i].account, amount);
                break;
            }
        }
    }

    function delegateToValidators(
        address[] memory validators,
        uint256 amount
    ) internal {
        // Call the delegate function on the Dpos contract
        // with the specified validator and amount
        // dposContract.delegate(validator);
    }

    event Staked(address indexed user, uint256 amount);
}
