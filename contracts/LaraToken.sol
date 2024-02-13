// SPDX-License-Identifier: MIT
// Security contact: elod@apeconsulting.xyz
pragma solidity 0.8.20;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract LaraToken is ERC20Upgradeable, OwnableUpgradeable {
    uint256 public minSwapAmount;
    uint256 public presaleStartBlock;
    uint256 public presaleEndBlock;
    uint256 public presaleBlockDuration;
    uint256 public swapUpperLimit;
    uint256 public presaleRate;
    uint16 public swapPeriod;
    address public treasuryAddress;
    bool public presaleRunning;

    uint256 private presaleStartCount;
    uint256 private presaleEndCount;

    mapping(address => uint256) public lastSwapBlock;

    event Swapped(address indexed user, uint256 amount);

    modifier onlyOnce() {
        require(presaleStartCount == 0, "Presale: start already called");
        _;
    }

    modifier onlyOnceEnd() {
        require(presaleEndCount == 0, "Presale: end already called");
        _;
    }

    function initialize(address _treasury) public initializer {
        __ERC20_init("Lara", "LARA");
        __Ownable_init(msg.sender);
        _mint(msg.sender, 10000000000 * 1e18);
        treasuryAddress = _treasury;
        minSwapAmount = 1000 ether;
        presaleBlockDuration = 151200;
        swapUpperLimit = 1000000 ether;
        presaleRate = 1724;
        swapPeriod = 900;
        presaleRunning = false;
    }

    receive() external payable {}

    fallback() external payable {}

    function startPresale() external onlyOnce {
        presaleStartBlock = block.number;
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
        require(
            msg.value <= swapUpperLimit,
            "Presale: you can swap max 1000000 LARA"
        );
        require(
            lastSwapBlock[msg.sender] == 0 ||
                (block.number >= lastSwapBlock[msg.sender] + swapPeriod),
            "Presale: you can swap once every 900 blocks"
        );
        lastSwapBlock[msg.sender] = block.number;
        uint256 laraAmount = (msg.value * presaleRate) / 100;
        _transfer(address(this), msg.sender, laraAmount);
        emit Swapped(msg.sender, laraAmount);
    }
}
