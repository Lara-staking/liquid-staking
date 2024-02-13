// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract Deployer {
    function deployUUPSProxy(
        string memory contractName,
        bytes memory data,
        Options memory opts
    ) public returns (address) {
        return Upgrades.deployUUPSProxy(contractName, data, opts);
    }

    function deployTransparentProxy(
        string memory contractName,
        address initialOwner,
        bytes memory data,
        Options memory opts
    ) public returns (address) {
        return
            Upgrades.deployTransparentProxy(
                contractName,
                initialOwner,
                data,
                opts
            );
    }

    function upgradeProxy(
        address proxy,
        string memory contractName,
        bytes memory data,
        Options memory opts
    ) public {
        Upgrades.upgradeProxy(proxy, contractName, data, opts);
    }

    function deployBeacon(
        string memory contractName,
        address initialOwner,
        Options memory opts
    ) public returns (address) {
        return Upgrades.deployBeacon(contractName, initialOwner, opts);
    }

    function upgradeBeacon(
        address beacon,
        string memory contractName,
        Options memory opts
    ) public {
        Upgrades.upgradeBeacon(beacon, contractName, opts);
    }

    function prepareUpgrade(
        string memory contractName,
        Options memory opts
    ) public {
        Upgrades.prepareUpgrade(contractName, opts);
    }
}
