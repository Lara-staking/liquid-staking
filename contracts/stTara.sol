// SPDX-License-Identifier: MIT
// Security contact: elod@apeconsulting.xyz
pragma solidity 0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IstTara} from "./interfaces/IstTara.sol";
import {IFactoryGoverned} from "./interfaces/IFactoryGoverned.sol";
import {Utils} from "./libs/Utils.sol";
import {LaraFactory} from "./LaraFactory.sol";
import {Lara} from "./Lara.sol";
import {FactoryGoverned} from "./FactoryGoverned.sol";

contract stTARA is ERC20, Ownable, IstTara, FactoryGoverned {
    // Events
    event Minted(address indexed user, uint256 amount);
    event Burned(address indexed user, uint256 amount);

    mapping(address => address[]) public larasOfDelegator;

    constructor() ERC20("Staked TARA", "stTARA") Ownable(msg.sender) {}

    function setLaraFactory(
        address _laraFactory
    ) external override(IFactoryGoverned, FactoryGoverned) onlyOwner {
        laraFactory = LaraFactory(_laraFactory);
    }

    function mint(
        address recipient,
        uint256 amount,
        address originLaraInstance
    ) external onlyLara {
        super._mint(recipient, amount);
        addLaraToDelegatorIfNotExists(recipient, originLaraInstance);
        emit Minted(recipient, amount);
    }

    function burn(address user, uint256 amount) external onlyLara {
        // Burn stTARA tokens
        super._burn(user, amount);
        adjustLarasForDelegator(user);
        emit Burned(user, amount);
    }

    function transfer(
        address to,
        uint256 amount
    ) public override(ERC20, IERC20) returns (bool) {
        _beforeTokenTransfer(_msgSender(), to, amount);
        return super.transfer(to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override(ERC20, IERC20) returns (bool) {
        _beforeTokenTransfer(from, to, value);
        return super.transferFrom(from, to, value);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(
            balanceOf(from) >= amount,
            "stTARA: transfer amount exceeds balance"
        );
        Utils.HolderData[]
            memory fromLaras = getLaraAddressesWithStakeForDelegator(
                from,
                amount
            );
        // readjust stakes
        for (uint256 i = 0; i < fromLaras.length; i++) {
            Lara laraInstance = Lara(payable(fromLaras[i].holder));
            laraInstance.transferStake(from, to, fromLaras[i].amount);
        }
    }

    event HolderData(address holder, uint256 amount);

    function getLaraAddressesWithStakeForDelegator(
        address delegator,
        uint256 stake
    ) internal returns (Utils.HolderData[] memory) {
        Utils.HolderData[] memory result = new Utils.HolderData[](
            larasOfDelegator[delegator].length
        );
        uint256 counter = 0;
        uint256 accountedAmount = 0;
        while (
            counter < larasOfDelegator[delegator].length ||
            accountedAmount < stake
        ) {
            Lara laraInstance = Lara(
                payable(larasOfDelegator[delegator][counter])
            );
            uint256 laraStake = laraInstance.stakeOf(delegator);
            if (laraStake > 0) {
                if (laraStake > stake) {
                    result[counter] = Utils.HolderData(
                        address(laraInstance),
                        stake
                    );
                } else {
                    result[counter] = Utils.HolderData(
                        address(laraInstance),
                        laraInstance.stakeOf(delegator)
                    );
                }
                emit HolderData(result[counter].holder, result[counter].amount);
                accountedAmount += result[counter].amount;
                counter++;
            }
        }
        // clean the result array
        Utils.HolderData[] memory temp = new Utils.HolderData[](counter);
        for (uint256 i = 0; i < counter; i++) {
            temp[i] = result[i];
            emit HolderData(temp[i].holder, temp[i].amount);
        }
        result = temp;
        return result;
    }

    function addLaraToDelegatorIfNotExists(
        address delegator,
        address lara
    ) internal {
        if (larasOfDelegator[delegator].length == 0) {
            larasOfDelegator[delegator].push(lara);
        } else {
            bool exists = false;
            for (uint256 i = 0; i < larasOfDelegator[delegator].length; i++) {
                if (larasOfDelegator[delegator][i] == lara) {
                    exists = true;
                    break;
                }
            }
            if (!exists) {
                larasOfDelegator[delegator].push(lara);
            }
        }
    }

    function adjustLarasForDelegator(address delegator) internal {
        address[] storage laras = larasOfDelegator[delegator];
        for (uint256 i = 0; i < laras.length; i++) {
            Lara laraInstance = Lara(payable(laras[i]));
            if (laraInstance.stakeOf(delegator) == 0) {
                Utils.removeAddressFromArray(
                    larasOfDelegator[delegator],
                    laras[i]
                );
            }
        }
    }
}
