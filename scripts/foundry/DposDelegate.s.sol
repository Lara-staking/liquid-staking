// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "../../contracts/stTara.sol";
import "../../contracts/interfaces/ILara.sol";
import "../../contracts/ApyOracle.sol";
import "./DeploymentAware.sol";

contract DelegateWithDpos is Script, DeploymentAware {
    uint256 public constant DELEGATE_AMOUNT = 1000000 ether;
    DposInterface dpos;
    ILara lara;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_KEY");
        address deployerAddress = vm.envAddress("DEPLOYER_ADDR");
        address dposAddress = vm.envAddress("DPOS_ADDRESS");
        address laraAddress = vm.envAddress("LARA_ADDRESS");
        vm.startBroadcast(deployerPrivateKey);

        lara = ILara(laraAddress);
        dpos = DposInterface(dposAddress);
        address[] memory nodes = new address[](1);
        nodes[0] = laraAddress;
        // dpos.delegate(deployerAddress, nodes);

        vm.stopBroadcast();
    }

    function delegateAmountToDpos() private {}
}
