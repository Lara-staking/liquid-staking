// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

abstract contract DeploymentAware {
    address public immutable DPOS_ADDRESS =
        address(0x00000000000000000000000000000000000000fe);
    address public immutable stTARA_ADDRESS =
        address(0xD312eDC59c8AAB3FC9e44773EAD796a445aED09E);
    address public immutable ORACLE_ADDRESS =
        address(0x3187C7486F6Aa40C520892766B9d8dcD3C23D9F1);
    address public immutable LARA_ADDRESS =
        address(0x352AF15174C6415A3e33970636F2019337a60C45);
}
