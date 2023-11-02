// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../interfaces/IApyOracle.sol";
import "../Lara.sol";
import "../ApyOracle.sol";
import "../mocks/MockDpos.sol";
import "../stTara.sol";
import {StakeAmountTooLow, StakeValueTooLow} from "../errors/SharedErrors.sol";

abstract contract ManyValidatorsTestSetup is Test {
    Lara lara;
    ApyOracle mockApyOracle;
    MockDpos mockDpos;
    stTARA stTaraToken;

    uint16 numValidators = 1800;

    address[] public validators = new address[](numValidators);

    event UpToThis(uint256 value);

    function setupValidators() public {
        // create a random array of addresses as internal validators
        for (uint16 i = 0; i < validators.length; i++) {
            validators[i] = vm.addr(i + 1);
        }

        // Set up the apy oracle with a random data feed address and a mock dpos contract
        vm.deal(address(mockDpos), 1000000 ether);
        emit UpToThis(12000000 ether);
        mockDpos = new MockDpos{value: 12000000 ether}(validators);
        emit UpToThis(1 ether);

        // check if MockDPos was initialized successfully
        assertEq(
            mockDpos.isValidatorRegistered(validators[0]),
            true,
            "MockDpos was not initialized successfully"
        );
        assertEq(
            mockDpos.isValidatorRegistered(validators[1]),
            true,
            "MockDpos was not initialized successfully"
        );
    }

    function setupApyOracle() public {
        mockApyOracle = new ApyOracle(address(this), address(mockDpos));

        // setting up the two validators in the mockApyOracle
        for (uint16 i = 0; i < validators.length; i++) {
            mockApyOracle.updateNodeData(
                validators[i],
                IApyOracle.NodeData({
                    account: validators[i],
                    rank: i,
                    apy: i,
                    fromBlock: 1,
                    toBlock: 15000,
                    rating: 813 //meaning 8.13
                })
            );
        }

        // check if the node data was set successfully
        assertEq(
            mockApyOracle.getNodeCount(),
            numValidators,
            "Node data was not set successfully"
        );
    }

    function setupLara() public {
        stTaraToken = new stTARA();
        lara = new Lara(
            address(stTaraToken),
            address(mockDpos),
            address(mockApyOracle)
        );
        stTaraToken.setLaraAddress(address(lara));
    }
}
