// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

abstract contract DeploymentAware {
    address public immutable DPOS_ADDRESS =
        address(0x00000000000000000000000000000000000000fe);
    address public immutable stTARA_ADDRESS =
        address(0xA162d038461676995B2eD8F2F6d63a297C912B71);
    address public immutable ORACLE_ADDRESS =
        address(0xa492eA1d9f90B4a9aD856D814b3329d48A228544);
    address public immutable LARA_ADDRESS =
        address(0xFad6e05a6C15866A2aA8400b778798Dd1d243b29);
    address public immutable WTARA_ADDRESS =
        address(0x5745CC77c362D459b78bC014d8940c2c98E08c54);
}
