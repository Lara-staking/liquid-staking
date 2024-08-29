// SPDX-License-Identifier: MIT
// Security contact: elod@apeconsulting.xyz
pragma solidity 0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {IstTara, ISnapshot} from "./interfaces/IstTara.sol";
import {ZeroAddress} from "./libs/SharedErrors.sol";
import {ERC20Snapshot, ERC20} from "./ERC20Snapshot.sol";

contract StakedNativeAsset is ERC20Snapshot, Ownable, Pausable, IstTara {
    // Thrown when the user does not have sufficient allowance set for Tara to burn
    error InsufficientUserAllowanceForBurn(uint256 amount, uint256 senderBalance, uint256 protocolBalance);

    // Address of Lara protocol
    address public lara;

    mapping(address => bool) public yieldBearingContracts;

    constructor() ERC20("Staked TARA", "stTARA") Ownable(msg.sender) Pausable() {}

    /**
     * @dev Modifier to ensure only Lara can call a function
     */
    modifier onlyLara() {
        require(msg.sender == lara, "Only Lara can call this function");
        _;
    }

    /**
     * @inheritdoc IstTara
     */
    function cumulativeBalanceOf(address user) external view returns (uint256) {
        if (user.code.length > 0) {
            if (yieldBearingContracts[user]) {
                return balanceOf(user);
            }
            return 0;
        }
        return balanceOf(user) + contractDepositOf(user);
    }

    /**
     * @inheritdoc IstTara
     */
    function cumulativeBalanceOfAt(address user, uint256 snapshotId) external view returns (uint256) {
        /// @notice if smart contract, return balanceOfAt() , else, to EOA return balanceOfAt() + wstTARA.balanceOfAt()
        if (user.code.length > 0) {
            if (yieldBearingContracts[user]) {
                return balanceOfAt(user, snapshotId);
            }
            return 0;
        }
        /// @notice if the user is the wstTARA contract, at any given point the balanceOfAt(address(wstTARA), snapshotId)
        /// must be equal to the totalSupplyAt(snapshotId)
        /// @notice However, for proper reward distribution, we need to return the current balance of the wstTARA contract in wstTARA

        return balanceOfAt(user, snapshotId) + contractDepositOfAt(user, snapshotId);
    }

    /// user --> stTARA --> wstTARA --> Uni v3 pool
    /// balanceOfAt(user, snapshotId) = 0                 => full stTARA + wstTARA supply = 2.5M
    /// wstTARA.balanceOfAt(user, snapshotId) = 2.5M

    /// user2 --> stTARA --> wstTARA --> Uni v3 pool
    /// balanceOfAt(user2, snapshotId) = 0                 => full stTARA + wstTARA supply = 7.5M
    /// wstTARA.balanceOfAt(user2, snapshotId) = 5M

    /// Uni v3 pool
    /// balanceOfAt(pool, snapshotId) = 0                 => full stTARA + wstTARA supply = 7.5M
    /// wstTARA.balanceOfAt(pool, snapshotId) = 7.5M

    /**
     * @inheritdoc ERC20Snapshot
     */
    function totalSupplyAt(uint256 snapshotId) public view override(ERC20Snapshot, IstTara) returns (uint256) {
        return super.totalSupplyAt(snapshotId);
    }

    /**
     * @inheritdoc IstTara
     */
    function setYieldBearingContract(address contractAddress) external onlyOwner {
        yieldBearingContracts[contractAddress] = true;
    }

    /**
     * @inheritdoc IstTara
     */
    function setLaraAddress(address _lara) external onlyOwner {
        lara = _lara;
    }

    /**
     * @inheritdoc ISnapshot
     */
    function snapshot() external override onlyLara returns (uint256) {
        return super._snapshot();
    }

    function mint(address recipient, uint256 amount) external onlyLara {
        if (recipient == address(0)) {
            revert ZeroAddress();
        }
        super._mint(recipient, amount);
    }

    function burn(address user, uint256 amount) external onlyLara {
        if (msg.sender != lara) {
            // Check if the amount is approved for lara to burn
            if (amount > allowance(user, lara)) {
                revert InsufficientUserAllowanceForBurn(amount, balanceOf(user), allowance(user, lara));
            }
        }
        // Burn stTARA tokens
        super._burn(user, amount);
    }
}
