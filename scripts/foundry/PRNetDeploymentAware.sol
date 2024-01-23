// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

abstract contract DeploymentAware {
    address public immutable DPOS_ADDRESS =
        address(0x00000000000000000000000000000000000000fe);
    address public immutable stTARA_ADDRESS =
        address(0x2aB6d071D1cb54E56F18ACA4D8482C3db37F6261);
    address public immutable ORACLE_ADDRESS =
        address(0x054708c7F560C30dD6bf6000100369E2B9d49465);
    address public immutable LARA_ADDRESS =
        address(0xa7d833782a45f112c4890Bc7b1f0ce6c62Dd0Da3);
}
