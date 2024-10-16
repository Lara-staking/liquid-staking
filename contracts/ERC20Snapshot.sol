// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/ERC20Snapshot.sol)
// Modified to add yield bearing contracts and contract deposits by Lara Protocol
// Security contact: dao@tlara.xyz

pragma solidity 0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Arrays} from "@openzeppelin/contracts/utils/Arrays.sol";
import {ISnapshot} from "./interfaces/ISnapshot.sol";
/**
 * @dev This contract extends an ERC20 token with a snapshot mechanism. When a snapshot is created, the balances and
 * total supply at the time are recorded for later access.
 *
 * This can be used to safely create mechanisms based on token balances such as trustless dividends or weighted voting.
 * In naive implementations it's possible to perform a "double spend" attack by reusing the same balance from different
 * accounts. By using snapshots to calculate dividends or voting power, those attacks no longer apply. It can also be
 * used to create an efficient ERC20 forking mechanism.
 *
 * Snapshots are created by the internal {_snapshot} function, which will emit the {Snapshot} event and return a
 * snapshot id. To get the total supply at the time of a snapshot, call the function {totalSupplyAt} with the snapshot
 * id. To get the balance of an account at the time of a snapshot, call the {balanceOfAt} function with the snapshot id
 * and the account address.
 *
 * NOTE: Snapshot policy can be customized by overriding the {_getCurrentSnapshotId} method. For example, having it
 * return `block.number` will trigger the creation of snapshot at the beginning of each new block. When overriding this
 * function, be careful about the monotonicity of its result. Non-monotonic snapshot ids will break the contract.
 *
 * Implementing snapshots for every block using this method will incur significant gas costs. For a gas-efficient
 * alternative consider {ERC20Votes}.
 *
 * ==== Gas Costs
 *
 * Snapshots are efficient. Snapshot creation is _O(1)_. Retrieval of balances or total supply from a snapshot is _O(log
 * n)_ in the number of snapshots that have been created, although _n_ for a specific account will generally be much
 * smaller since identical balances in subsequent snapshots are stored as a single entry.
 *
 * There is a constant overhead for normal ERC20 transfers due to the additional snapshot bookkeeping. This overhead is
 * only significant for the first transfer that immediately follows a snapshot for a particular account. Subsequent
 * transfers will have normal cost until the next snapshot, and so on.
 */

abstract contract ERC20Snapshot is ERC20, ISnapshot {
    // Inspired by Jordi Baylina's MiniMeToken to record historical balances:
    // https://github.com/Giveth/minime/blob/ea04d950eea153a04c51fa510b068b9dded390cb/contracts/MiniMeToken.sol
    // Modified to add yield bearing contracts and contract deposits by Lara Protocol

    using Arrays for uint256[];

    // Snapshotted values have arrays of ids and the value corresponding to that id. These could be an array of a
    // Snapshot struct, but that would impede usage of functions that work on an array.
    struct Snapshots {
        uint256[] ids;
        uint256[] values;
        uint256[] contractDeposits;
    }

    mapping(address => Snapshots) private _accountBalanceSnapshots;
    Snapshots private _totalSupplySnapshots;

    mapping(address => uint256) private _contractDeposits;

    mapping(address => bool) private _yieldBearingContracts;

    // Snapshot ids increase monotonically, with the first value being 1. An id of 0 is invalid.
    uint256 private _currentSnapshotId;

    /**
     * @dev Emitted by {_snapshot} when a snapshot identified by `id` is created.
     */
    event Snapshot(uint256 id);
    event YieldBearingContractSet(address indexed contractAddress);
    event AccountSnapshotUpdated(address indexed account, uint256 balance);
    event TotalSupplySnapshotUpdated(uint256 totalSupply);
    event ContractSnapshotUpdated(address indexed contractAddress, uint256 contractDeposit);

    /**
     * @dev Creates a new snapshot and returns its snapshot id.
     *
     * Emits a {Snapshot} event that contains the same id.
     *
     * {_snapshot} is `internal` and you have to decide how to expose it externally. Its usage may be restricted to a
     * set of accounts, for example using {AccessControl}, or it may be open to the public.
     *
     * [WARNING]
     * ====
     * While an open way of calling {_snapshot} is required for certain trust minimization mechanisms such as forking,
     * you must consider that it can potentially be used by attackers in two ways.
     *
     * First, it can be used to increase the cost of retrieval of values from snapshots, although it will grow
     * logarithmically thus rendering this attack ineffective in the long term. Second, it can be used to target
     * specific accounts and increase the cost of ERC20 transfers for them, in the ways specified in the Gas Costs
     * section above.
     *
     * We haven't measured the actual numbers; if this is something you're interested in please reach out to us.
     * ====
     */
    function _snapshot() internal virtual returns (uint256) {
        _currentSnapshotId++;

        uint256 currentId = _getCurrentSnapshotId();
        _updateTotalSupplySnapshot();
        emit Snapshot(currentId);
        return currentId;
    }

    /**
     * @dev Set a yield bearing contract
     * @param contractAddress the contract address
     * Yield-bearing concept is used to track the contract deposits of addresses sending(depositing) tokens to yield bearing contracts
     * This is used to properly forward yields of the extending rebasing token to the depositors in case of contracts that are not aware of the rebasing token(non yield bearing contracts)
     * Contracts that are aware of the rebasing token are added to the yield bearing contracts mapping and are reciving the yields from the extending rebasing token
     */
    function _setYieldBearingContract(address contractAddress) internal virtual {
        _yieldBearingContracts[contractAddress] = true;
        emit YieldBearingContractSet(contractAddress);
    }

    /**
     * @dev Check if a contract is a yield bearing contract
     * @param contractAddress the contract address
     * @return bool true if the contract is a yield bearing contract, false otherwise
     */
    function isYieldBearingContract(address contractAddress) public view returns (bool) {
        return _yieldBearingContracts[contractAddress];
    }

    /**
     * @dev Get the current snapshotId
     */
    function _getCurrentSnapshotId() internal view virtual returns (uint256) {
        return _currentSnapshotId;
    }

    /**
     * @dev Get the contract deposit of an address
     * @param account the address
     * @return uint256 the contract deposit of the address
     */
    function contractDepositOf(address account) public view virtual returns (uint256) {
        return _contractDeposits[account];
    }

    /**
     * @dev Retrieves the balance of `account` at the time `snapshotId` was created.
     * @param account the address
     * @param snapshotId the snapshot id
     * @return uint256 the balance of the address at the time of the snapshot
     */
    function balanceOfAt(address account, uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _accountBalanceSnapshots[account]);

        return snapshotted ? value : balanceOf(account);
    }

    /**
     * @dev Retrieves the total supply at the time `snapshotId` was created.
     * @param snapshotId the snapshot id
     * @return uint256 the total supply at the time of the snapshot
     */
    function totalSupplyAt(uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _totalSupplySnapshots);

        return snapshotted ? value : totalSupply();
    }

    /**
     * @dev Retrieves the contract deposit of `account` at the time `snapshotId` was created.
     * @param account the address
     * @param snapshotId the snapshot id
     * @return uint256 the contract deposit of the address at the time of the snapshot
     */
    function contractDepositOfAt(address account, uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _contractValueAt(snapshotId, _accountBalanceSnapshots[account]);

        return snapshotted ? value : contractDepositOf(account);
    }

    function _isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    /**
     * @dev Update balance and/or total supply snapshots before the values are modified. This is implemented
     * in the _beforeTokenTransfer hook, which is executed for _mint, _burn, and _transfer operations.
     * @param from the address
     * @param to the address
     * @param amount the amount
     * @notice This method is modified to include the contract deposits in the snapshots
     */
    function _update(address from, address to, uint256 amount) internal virtual override {
        super._update(from, to, amount);

        if (from == address(0)) {
            // mint
            _updateAccountSnapshot(to);
            _updateTotalSupplySnapshot();
        } else if (to == address(0)) {
            // burn
            _updateAccountSnapshot(from);
            _updateTotalSupplySnapshot();
        } else {
            // transfer
            _updateAccountSnapshot(from);
            _updateAccountSnapshot(to);
        }

        if (_isContract(to)) {
            if (!isYieldBearingContract(to)) {
                _contractDeposits[from] += amount;
            }
            if (_isContract(from) && !isYieldBearingContract(from)) {
                _contractDeposits[from] -= amount;
            }
            _updateContractSnapshot(from);
            _updateContractSnapshot(to);
        }
    }

    /**
     * @dev Retrieves the value at the time `snapshotId` was created.
     * @param snapshotId the snapshot id
     * @param snapshots the snapshots
     * @return bool true if the value was found, false otherwise
     * @return uint256 the value at the time of the snapshot
     */
    function _valueAt(uint256 snapshotId, Snapshots storage snapshots) private view returns (bool, uint256) {
        require(snapshotId != 0, "ERC20Snapshot: id is 0");
        require(snapshotId <= _getCurrentSnapshotId(), "ERC20Snapshot: nonexistent id");

        // When a valid snapshot is queried, there are three possibilities:
        //  a) The queried value was not modified after the snapshot was taken. Therefore, a snapshot entry was never
        //  created for this id, and all stored snapshot ids are smaller than the requested one. The value that corresponds
        //  to this id is the current one.
        //  b) The queried value was modified after the snapshot was taken. Therefore, there will be an entry with the
        //  requested id, and its value is the one to return.
        //  c) More snapshots were created after the requested one, and the queried value was later modified. There will be
        //  no entry for the requested id: the value that corresponds to it is that of the smallest snapshot id that is
        //  larger than the requested one.
        //
        // In summary, we need to find an element in an array, returning the index of the smallest value that is larger if
        // it is not found, unless said value doesn't exist (e.g. when all values are smaller). Arrays.findUpperBound does
        // exactly this.

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    /**
     * @dev Retrieves the contract deposit of `account` at the time `snapshotId` was created.
     * @param snapshotId the snapshot id
     * @param snapshots the snapshots
     * @return bool true if the value was found, false otherwise
     * @return uint256 the value at the time of the snapshot
     */
    function _contractValueAt(uint256 snapshotId, Snapshots storage snapshots) private view returns (bool, uint256) {
        require(snapshotId > 0, "ERC20Snapshot: id is 0");
        require(snapshotId <= _getCurrentSnapshotId(), "ERC20Snapshot: nonexistent id");

        // When a valid snapshot is queried, there are three possibilities:
        //  a) The queried value was not modified after the snapshot was taken. Therefore, a snapshot entry was never
        //  created for this id, and all stored snapshot ids are smaller than the requested one. The value that corresponds
        //  to this id is the current one.
        //  b) The queried value was modified after the snapshot was taken. Therefore, there will be an entry with the
        //  requested id, and its value is the one to return.
        //  c) More snapshots were created after the requested one, and the queried value was later modified. There will be
        //  no entry for the requested id: the value that corresponds to it is that of the smallest snapshot id that is
        //  larger than the requested one.
        //
        // In summary, we need to find an element in an array, returning the index of the smallest value that is larger if
        // it is not found, unless said value doesn't exist (e.g. when all values are smaller). Arrays.findUpperBound does
        // exactly this.

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.contractDeposits[index]);
        }
    }

    /**
     * @dev Update the balance snapshot of an account
     * @param account the address
     */
    function _updateAccountSnapshot(address account) private {
        _updateSnapshot(_accountBalanceSnapshots[account], balanceOf(account), 0);
        emit AccountSnapshotUpdated(account, balanceOf(account));
    }

    /**
     * @dev Update the total supply snapshot
     */
    function _updateTotalSupplySnapshot() private {
        _updateSnapshot(_totalSupplySnapshots, totalSupply(), 0);
        emit TotalSupplySnapshotUpdated(totalSupply());
    }

    /**
     * @dev Update the snapshot
     * @param snapshots the snapshots
     * @param currentValue the current value
     * @param currentContractDeposit the current contract deposit
     */
    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue, uint256 currentContractDeposit)
        private
    {
        uint256 currentId = _getCurrentSnapshotId();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
            snapshots.contractDeposits.push(currentContractDeposit);
        }
    }

    /**
     * @dev Update the contract snapshot
     * @param contractAddress the contract address
     */
    function _updateContractSnapshot(address contractAddress) private {
        _updateSnapshot(_accountBalanceSnapshots[contractAddress], 0, contractDepositOf(contractAddress));
        emit ContractSnapshotUpdated(contractAddress, contractDepositOf(contractAddress));
    }

    /**
     * @dev Retrieve the last snapshot id
     * @param ids the snapshot ids
     * @return uint256 the last snapshot id
     */
    function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }
}
