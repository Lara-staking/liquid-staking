// SPDX-License-Identifier: MIT
// Security contact: elod.varga@taraxa.io
pragma solidity 0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ReentrancyGuard} from "./ReentrancyGuard.sol";

contract LaraToken is ERC20, ReentrancyGuard {
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

    constructor(address _treasury) ERC20("Lara", "LARA") ReentrancyGuard() {
        _mint(msg.sender, 1000000000 ether);
        require(_treasury != address(0), "Presale: treasury address is the zero address");
        treasuryAddress = _treasury;
        minSwapAmount = 1000 ether;
        presaleBlockDuration = 151200;
        swapUpperLimit = 1000000 ether;
        presaleRate = 4;
        swapPeriod = 900;
        presaleRunning = false;
    }

    receive() external payable {}

    fallback() external payable {}

    /**
     * @dev Start the presale
     */
    function startPresale() external onlyOnce nonReentrant {
        require(treasuryAddress != address(0), "Presale: treasury address is the zero address");
        require(balanceOf(address(this)) == totalSupply() / 10, "Presale: incorrect initial presale balance");
        presaleStartBlock = block.number;
        presaleRunning = true;
        presaleStartCount++;
    }

    /**
     * @dev End the presale
     */
    function endPresale() external onlyOnceEnd nonReentrant {
        require(presaleStartBlock > 0, "Presale: presale not started");
        require(presaleRunning, "Presale: presale not running");
        require(block.number >= presaleStartBlock + presaleBlockDuration, "Presale: presale not ended");
        require(presaleEndBlock == 0, "Presale: already ended");
        require(treasuryAddress != address(0), "Presale: treasury address is the zero address");
        presaleRunning = false;
        presaleEndCount++;
        presaleEndBlock = block.number;
        (bool success,) = treasuryAddress.call{value: address(this).balance}("");
        if (!success) {
            revert("Presale: transfer failed");
        }
        if (balanceOf(address(this)) > 0) {
            _burn(address(this), balanceOf(address(this)));
        }
    }

    /**
     * @dev Swap function
     */
    function swap() external payable nonReentrant {
        require(presaleRunning, "Presale: presale not running");
        require(presaleStartBlock > 0, "Presale: presale not started");
        require(msg.value >= minSwapAmount, "Presale: amount too low");
        require(balanceOf(address(this)) >= msg.value * presaleRate, "Presale: insufficient balance");
        require(msg.value <= swapUpperLimit, "Presale: you can swap max 1000000 TARA");
        require(
            lastSwapBlock[msg.sender] == 0 || (block.number >= lastSwapBlock[msg.sender] + swapPeriod),
            "Presale: you can swap once every 900 blocks"
        );
        uint256 laraAmount = msg.value * presaleRate;
        _transfer(address(this), msg.sender, laraAmount);
        if (balanceOf(msg.sender) >= presaleRate * swapUpperLimit) {
            lastSwapBlock[msg.sender] = block.number;
        }
        emit Swapped(msg.sender, laraAmount);
    }
}
