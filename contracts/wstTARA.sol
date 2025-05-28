// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IstTara} from "./interfaces/IstTara.sol";

contract WrappedStTara is ERC20, ERC4626, ERC20Permit {
    IstTara public immutable stTARA;

    constructor(address _stTARA)
        ERC20("Wrapped Staked TARA", "wstTARA")
        ERC20Permit("Wrapped Staked TARA")
        ERC4626(IERC20(_stTARA))
    {
        stTARA = IstTara(_stTARA);
    }

    function decimals() public pure override(ERC20, ERC4626) returns (uint8) {
        return 18;
    }
}
