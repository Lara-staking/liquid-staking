// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract DeploymentAware {
    address public immutable DPOS_ADDRESS =
        address(0x00000000000000000000000000000000000000fe);
    address public immutable stTARA_ADDRESS =
        address(0xd5696f2156325034f3aD1d1D6D13bb73c0e3b1E5);
    address public immutable ORACLE_ADDRESS =
        address(0x72B6B11CA6dFc90DC9840e038253133381FA57f9);
    address public immutable LARA_ADDRESS =
        address(0x40Fb69932669A92b0cB01DEF620d6758b9ab1393);
}
