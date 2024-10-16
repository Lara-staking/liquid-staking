// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {IApyOracle} from "../interfaces/IApyOracle.sol";
import {Lara} from "../Lara.sol";
import {ApyOracle} from "../ApyOracle.sol";
import {MockDpos} from "../mocks/MockDpos.sol";
import {StakedNativeAsset} from "../StakedNativeAsset.sol";
import {LaraV2Test} from "./LaraV2Test.sol";
import {StakeAmountTooLow} from "../libs/SharedErrors.sol";

contract UpgradeTest is Test {
    Lara lara;
    ApyOracle mockApyOracle;
    MockDpos mockDpos;
    StakedNativeAsset stTaraToken;

    address treasuryAddress = address(9999);

    uint16 numValidators = 12;

    address[] validators = new address[](numValidators);

    fallback() external payable {}

    receive() external payable {}

    function setUp() public {}

    function testUpgradeProxy() public {
        setupValidators();
        setupApyOracle();
        setupLara();

        address treasury = lara.treasuryAddress();

        Upgrades.upgradeProxy(address(lara), "LaraV2Test.sol", abi.encodeCall(LaraV2Test.setRandomSlot, (21)));

        LaraV2Test laraV2 = LaraV2Test(payable(address(lara)));

        assertEq(laraV2.treasuryAddress(), treasury, "Treasury address should be the same");
        assertEq(laraV2.getRandomSlot(), 21, "Random slot should be 21");
    }

    function setupValidators() public {
        // create a random array of addresses as internal validators
        for (uint16 i = 0; i < validators.length; i++) {
            validators[i] = vm.addr(i + 1);
        }

        // Set up the apy oracle with a random data feed address and a mock dpos contract
        vm.deal(address(mockDpos), 1000000 ether);
        mockDpos = new MockDpos{value: 12000000 ether}(validators);

        // check if MockDPos was initialized successfully
        assertEq(mockDpos.isValidatorRegistered(validators[0]), true, "MockDpos was not initialized successfully");
        assertEq(mockDpos.isValidatorRegistered(validators[1]), true, "MockDpos was not initialized successfully");
    }

    function setupApyOracle() public {
        address proxy = Upgrades.deployUUPSProxy(
            "ApyOracle.sol", abi.encodeCall(ApyOracle.initialize, (address(this), address(mockDpos)))
        );
        mockApyOracle = ApyOracle(proxy);

        // setting up the two validators in the mockApyOracle
        for (uint16 i = 0; i < validators.length; i++) {
            mockApyOracle.updateNodeData(
                validators[i],
                IApyOracle.NodeData({
                    account: validators[i],
                    rank: i,
                    apy: i * 1000,
                    fromBlock: 1,
                    toBlock: 15000,
                    rating: 813 //meaning 8.13
                })
            );
        }

        // check if the node data was set successfully
        assertEq(mockApyOracle.getNodeCount(), numValidators, "Node data was not set successfully");
    }

    function setupLara() public {
        stTaraToken = new StakedNativeAsset();
        address laraProxy = Upgrades.deployUUPSProxy(
            "Lara.sol",
            abi.encodeCall(
                Lara.initialize, (address(stTaraToken), address(mockDpos), address(mockApyOracle), treasuryAddress)
            )
        );
        lara = Lara(payable(laraProxy));
        stTaraToken.setLaraAddress(address(lara));
        mockApyOracle.setLara(address(lara));
        assertEq(mockApyOracle.lara(), address(lara), "Lara address was not set successfully");
    }

    function setupLaraWithCommission(uint256 commission) public {
        stTaraToken = new StakedNativeAsset();
        lara = new Lara();
        lara.initialize(address(stTaraToken), address(mockDpos), address(mockApyOracle), treasuryAddress);
        stTaraToken.setLaraAddress(address(lara));
        mockApyOracle.setLara(address(lara));
        assertEq(mockApyOracle.lara(), address(lara), "Lara address was not set successfully");
        lara.setCommission(commission);
    }

    function findValidatorWithStake(uint256 stake) public view returns (address) {
        for (uint256 i = 0; i < validators.length; i++) {
            if (lara.protocolTotalStakeAtValidator(validators[i]) == stake) {
                return validators[i];
            }
        }
        return address(0);
    }

    function batchUpdateNodeData(uint16 multiplier, bool reverse) public {
        IApyOracle.NodeData[] memory nodeData = new IApyOracle.NodeData[](validators.length);
        if (reverse) {
            for (uint16 i = uint16(validators.length); i > 0; i--) {
                nodeData[validators.length - i] = IApyOracle.NodeData({
                    account: validators[i - 1],
                    rank: uint16(validators.length - i),
                    apy: 1000 - i * multiplier,
                    fromBlock: 1,
                    toBlock: 15000,
                    rating: 813 + i * 10 * multiplier //meaning 8.13
                });
            }
        } else {
            for (uint16 i = 0; i < validators.length; i++) {
                nodeData[i] = IApyOracle.NodeData({
                    account: validators[i],
                    rank: i + 1,
                    apy: 1000 - i * multiplier,
                    fromBlock: 1,
                    toBlock: 15000,
                    rating: 813 + (validators.length - i) * 10 * multiplier
                });
            }
        }
        mockApyOracle.batchUpdateNodeData(nodeData);
    }
}
