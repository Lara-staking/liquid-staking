// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

abstract contract DeploymentAware {
    address public immutable DPOS_ADDRESS =
        address(0x00000000000000000000000000000000000000fe);
    address public immutable stTARA_ADDRESS =
        address(0x5dcd581597184f0dc3FeaA8c32Be7ec2CadaD1E7);
    address public immutable ORACLE_ADDRESS =
        address(0xE17B595748E6207A9416d9FEB07139cA437054bf);
    address public immutable LARA_ADDRESS =
        address(0x1Bd2a34798DE625151ba124D457cfdc620d0579b);
}
