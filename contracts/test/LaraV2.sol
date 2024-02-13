// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../Lara.sol";

/// @custom:oz-upgrades-from Lara
contract LaraV2 is Lara {
    function initialize_V2(
        address _sttaraToken,
        address _dposContract,
        address _apyOracle,
        address _treasuryAddress
    ) public initializer {
        super.initialize(
            _sttaraToken,
            _dposContract,
            _apyOracle,
            _treasuryAddress
        );
    }
}
