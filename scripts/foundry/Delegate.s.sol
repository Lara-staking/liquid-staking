// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Script.sol";
import "../../contracts/stTara.sol";
import "../../contracts/interfaces/ILara.sol";
import "../../contracts/interfaces/IDPOS.sol";
import "../../contracts/interfaces/IApyOracle.sol";
import "../../contracts/interfaces/IstTara.sol";
import "./DeploymentAware.sol";

contract Delegate is Script, DeploymentAware {
    uint256 public constant DELEGATE_AMOUNT = 1000000 ether;
    DposInterface dpos;
    ILara lara;
    IApyOracle oracle;
    IstTara stTara;

    event Eligible(address addr);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_KEY");
        address dposAddress = vm.envAddress("DPOS_ADDRESS");
        address laraAddress = vm.envAddress("LARA_ADDRESS");
        address oracleAddress = vm.envAddress("ORACLE_ADDRESS");
        vm.startBroadcast(deployerPrivateKey);

        lara = ILara(laraAddress);
        dpos = DposInterface(dposAddress);
        oracle = IApyOracle(oracleAddress);
        stTara = IstTara(stTARA_ADDRESS);
        // stTara.setLaraAddress(laraAddress);
        address[] memory nodes = new address[](4);
        nodes[0] = address(0xC578Bb5fc3DAC3e96a8c4cb126c71d2Dc9082817);
        nodes[1] = address(0x5C9Afb23fBA3967CA6102Fb60C9949F6A38CD9e8);
        nodes[2] = address(0x5042fA2711Fe547e46C2f64852FDaA5982C80697);
        nodes[3] = address(0x6258d8F51eA17e873f69A2a978fe311fd95743dD);

        for (uint256 i = 0; i < nodes.length; i++) {
            (bool success, bytes memory data) = address(dpos).call(
                abi.encodeWithSignature(
                    "isValidatorEligible(address)",
                    nodes[i]
                )
            );
            if (!success) {
                revert("isValidatorEligible failed");
            }

            bool eligible = abi.decode(data, (bool));
            if (eligible) {
                emit Eligible(nodes[i]);
            }
        }
        uint256 amount = 100000 ether;
        startStaking(amount);
        vm.stopBroadcast();
    }

    function delegateAmountToDpos(
        uint256 amount,
        address[] memory nodes
    ) private {
        for (uint256 i = 0; i < nodes.length; i++) {
            dpos.delegate{value: amount}(nodes[i]);
        }
    }

    function getValidatorFromDpos(
        address validtator
    ) public returns (DposInterface.ValidatorBasicInfo memory) {
        return dpos.getValidator(validtator);
    }

    function getDelegatorsForAmountFromOracle(
        uint256 amount
    ) private returns (address[] memory) {
        IApyOracle.TentativeDelegation[] memory delegations = oracle
            .getNodesForDelegation(amount);
        address[] memory nodes = new address[](delegations.length);
        for (uint256 i = 0; i < delegations.length; i++) {
            IApyOracle.TentativeDelegation memory delegation = delegations[i];
            if (delegation.amount > 0) {
                nodes[i] = delegation.validator;
            }
        }
        return nodes;
    }

    function startStaking(uint256 amount) private {
        // DposInterface.ValidatorBasicInfo
        //     memory validator = getValidatorFromDpos(
        //         address(0xC578Bb5fc3DAC3e96a8c4cb126c71d2Dc9082817)
        //     );
        IApyOracle.TentativeDelegation[] memory delegations = lara
            .getValidatorsForAmount(amount);
        for (uint256 i = 0; i < delegations.length; i++) {
            IApyOracle.TentativeDelegation memory delegation = delegations[i];
            if (delegation.amount > 0) {
                (bool success, ) = address(dpos).call{value: delegation.amount}(
                    abi.encodeWithSignature(
                        "delegate(address)",
                        delegation.validator
                    )
                );
                if (!success) {
                    revert("isValidatorEligible failed");
                }
            }
        }
        lara.stake{value: amount}(amount);

        address[] memory stakeNodes = getDelegatorsForAmountFromOracle(amount);
        delegateAmountToDpos(amount, stakeNodes);
        lara.startEpoch();
    }
}
