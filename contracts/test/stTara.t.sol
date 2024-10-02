// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {IApyOracle} from "@contracts/interfaces/IApyOracle.sol";
import {Lara} from "@contracts/Lara.sol";
import {ApyOracle} from "@contracts/ApyOracle.sol";
import {MockDpos} from "@contracts/mocks/MockDpos.sol";
import {StakedNativeAsset} from "@contracts/StakedNativeAsset.sol";
import {TestSetup} from "@contracts/test/SetUp.t.sol";
import {StakeAmountTooLow, StakeValueTooLow} from "@contracts/libs/SharedErrors.sol";

contract UndelegateTest is Test, TestSetup {
    function setUp() public {
        super.setupValidators();
        super.setupApyOracle();
        super.setupLara();
    }
}
