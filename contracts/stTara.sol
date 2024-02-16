// SPDX-License-Identifier: MIT
// Security contact: elod@apeconsulting.xyz
pragma solidity 0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IstTara} from "./interfaces/IstTara.sol";
import {IFactoryGoverned} from "./interfaces/IFactoryGoverned.sol";
import {Utils} from "./libs/Utils.sol";
import {LaraFactory} from "./LaraFactory.sol";
import {FactoryGoverned} from "./FactoryGoverned.sol";

contract stTARA is ERC20, Ownable, IstTara, FactoryGoverned {
    // Events
    event Minted(address indexed user, uint256 amount);
    event Burned(address indexed user, uint256 amount);

    constructor() ERC20("Staked TARA", "stTARA") Ownable(msg.sender) {}

    function setLaraFactory(
        address _laraFactory
    ) external override(IFactoryGoverned, FactoryGoverned) onlyOwner {
        laraFactory = LaraFactory(_laraFactory);
    }

    function mint(address recipient, uint256 amount) external onlyLara {
        super._mint(recipient, amount);

        emit Minted(recipient, amount);
    }

    function burn(address user, uint256 amount) external onlyLara {
        // Burn stTARA tokens
        super._burn(user, amount);
        emit Burned(user, amount);
    }
}
