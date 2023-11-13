// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract DeploymentAware {
    address public immutable DPOS_ADDRESS =
        address(0x00000000000000000000000000000000000000fe);
    address public immutable stTARA_ADDRESS =
        address(0xDe7AFfaf7f677CCEE245eC1fF973bBa326D8b48E);
    address public immutable ORACLE_ADDRESS =
        address(0x5a66Ab212bca20B7602d11bF49D56f93507B0FFB);
    address public immutable LARA_ADDRESS =
        address(0x91c6aCCFD788fe42cF8D96EB355B855F337c1950);
}
