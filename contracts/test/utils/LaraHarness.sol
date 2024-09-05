// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Lara} from "../../Lara.sol";

contract LaraHarness is Lara {
    function initializeIt(address _sttaraToken, address _dposContract, address _apyOracle, address _treasuryAddress)
        public
        initializer
    {
        super.initialize(_sttaraToken, _dposContract, _apyOracle, _treasuryAddress);
    }

    function delegateToValidators(uint256 amount) public returns (uint256) {
        return _delegateToValidators(amount);
    }
}
