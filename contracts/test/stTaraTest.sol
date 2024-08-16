// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {IApyOracle} from "../interfaces/IApyOracle.sol";
import {Lara} from "../Lara.sol";
import {ApyOracle} from "../ApyOracle.sol";
import {MockDpos} from "../mocks/MockDpos.sol";
import {StakedNativeAsset} from "../StakedNativeAsset.sol";
import {TestSetup} from "./SetUpTest.sol";
import {StakeAmountTooLow, StakeValueTooLow} from "../libs/SharedErrors.sol";

contract UndelegateTest is Test, TestSetup {
    function setUp() public {
        super.setupValidators();
        super.setupApyOracle();
        super.setupLara();
    }
}
