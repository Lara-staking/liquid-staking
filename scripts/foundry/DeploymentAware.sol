// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract DeploymentAware {
    address public immutable DPOS_ADDRESS =
        address(0x00000000000000000000000000000000000000fe);
    address public immutable stTARA_ADDRESS =
        address(0x4f080Db0d36b9d9bD0446D8718108C6D0D99EB34);
    address public immutable ORACLE_ADDRESS =
        address(0x01BE93E3563f384bf7121E45619bAA6D8F62010B);
    address public immutable LARA_ADDRESS =
        address(0x5D23F0A99d2503a1DA03a4a36f1e60C6ac6AA3F2);
}
