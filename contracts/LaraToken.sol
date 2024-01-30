// SPDX-License-Identifier: MIT
// Security contact: elod@apeconsulting.xyz
pragma solidity 0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract LaraToken is ERC20, Ownable {
    uint256 public minSwapAmount = 1000 ether;
    uint256 public presaleStartBlock;
    uint256 public presaleEndBlock;
    uint256 public presaleBlockDuration = 151200;
    uint256 public presaleRate = 1724;
    address public treasuryAddress;
    bool public presaleRunning = false;

    uint256 private presaleStartCount = 0;
    uint256 private presaleEndCount = 0;

    modifier onlyOnce() {
        require(presaleStartCount == 0, "Presale: start already called");
        _;
    }

    modifier onlyOnceEnd() {
        require(presaleEndCount == 0, "Presale: end already called");
        _;
    }

    constructor(address _treasury) ERC20("Lara", "LARA") Ownable(msg.sender) {
        _mint(msg.sender, 1000000000 * 1e18);
        treasuryAddress = _treasury;
    }

    receive() external payable {}

    fallback() external payable {}

    function startPresale(uint256 _presaleStartBlock) external onlyOnce {
        presaleStartBlock = _presaleStartBlock;
        presaleRunning = true;
        presaleStartCount++;
    }

    function endPresale() external onlyOnceEnd {
        require(presaleStartBlock > 0, "Presale: presale not started");
        require(presaleRunning, "Presale: presale not running");
        require(
            block.number >= presaleStartBlock + presaleBlockDuration,
            "Presale: presale not ended"
        );
        require(presaleEndBlock == 0, "Presale: already ended");
        presaleRunning = false;
        presaleEndCount++;
        presaleEndBlock = block.number;
        (bool success, ) = treasuryAddress.call{value: address(this).balance}(
            ""
        );
        if (!success) {
            revert("Presale: transfer failed");
        }
        if (balanceOf(address(this)) > 0) {
            _burn(address(this), balanceOf(address(this)));
        }
    }

    function swap() external payable {
        require(presaleRunning, "Presale: presale not running");
        require(presaleStartBlock > 0, "Presale: presale not started");
        require(msg.value >= minSwapAmount, "Presale: amount too low");
        require(
            balanceOf(address(this)) >= msg.value,
            "Presale: insufficient balance"
        );
        uint256 laraAmount = (msg.value * presaleRate) / 100;
        _transfer(address(this), msg.sender, laraAmount);
    }
}
