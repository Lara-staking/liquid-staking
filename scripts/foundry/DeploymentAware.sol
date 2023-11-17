// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract DeploymentAware {
    address public immutable DPOS_ADDRESS =
        address(0x00000000000000000000000000000000000000fe);
    address public immutable stTARA_ADDRESS =
        address(0x6E1f2201BF8aEce5Ec01Ee0F09abA7c9BA115033);
    address public immutable ORACLE_ADDRESS =
        address(0x56df779662b9868812E1e84fcb3548883143EDbb);
    address public immutable LARA_ADDRESS =
        address(0xAacb01815523d364c90355c5FFC9BDbf958Dec9E);
}
