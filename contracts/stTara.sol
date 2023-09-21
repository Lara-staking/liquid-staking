// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract stTARA is ERC20, Ownable {
    // Errors

    // Thrown when the amount sent for minting is lower than min allowed
    error DepositAmountTooLow(uint256 amount, uint256 minAmount);
    
    // Thrown when the value sent for the mint by an user is lower than min allowed
    error MintValueTooLow(uint256 sentAmount, uint256 minAmount);
    
    // Thrown when the burn caller is not the user or the lara protocol
    error WrongBurnAddress(address wrongAddress);

    error InsufficientBalanceForBurn(uint256 amount, uint256 senderBalance);
    
    // Events
    event Minted(address indexed user, uint256 amount);
    event Burned(address indexed user, uint256 amount);

    // State variables
    uint256 public minDepositAmount = 1000 ether;

    // Address of Lara protocol
    address public lara;

    // Mapping holding for each user the balance minted using Lara, currently unclaimed
    mapping(address => uint256) protocolBalances;

    constructor() ERC20("Staked TARA", "stTARA") {}

    function setMinDepositAmount(uint256 _minDepositAmount) external onlyOwner {
        minDepositAmount = _minDepositAmount;
    }

    function setLaraAddress(address _lara) external onlyOwner {    
        lara = _lara;
    }

    function mint(address recipient, uint256 amount) external payable {
        if(amount < minDepositAmount)
            revert DepositAmountTooLow(amount, minDepositAmount);
        if(msg.sender == lara) {
            protocolBalances[recipient] += amount;
            
        } else {
            if(msg.value < amount) 
                revert MintValueTooLow(msg.value, minDepositAmount);
            amount = msg.value;
            _mint(recipient, amount);
        }
        
        emit Minted(recipient, amount);
    }

    function burn(address user, uint256 amount) external {
        if(user != msg.sender || user != lara)
            revert WrongBurnAddress(user);
        if(user == msg.sender) {
            if(balanceOf(user) -  protocolBalances[user] < amount) 
                revert InsufficientBalanceForBurn(amount, balanceOf(msg.sender));
            // Transfer TARA tokens to the user
            payable(msg.sender).transfer(amount);
        } else { //lara == msg.sender. In this case the protocol will pay back the user also with the rewards
            if(amount > protocolBalances[user])
                revert InsufficientBalanceForBurn(amount, protocolBalances[user]);
        }
        // Burn stTARA tokens
        _burn(user, amount);

        

        emit Burned(user, amount);
    }
}
