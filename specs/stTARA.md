# Specification Document - stTARA Contract

## Business Logic

The `stTARA` contract serves as an ERC-20 token representing staked TARA on the Taraxa blockchain. Its primary purpose is to enable users to stake TARA and receive stTARA tokens in return, which can be used to represent and manage their staked TARA holdings. Users can also burn stTARA tokens to retrieve their staked TARA.

### Token Minting and Burning

- Users can mint stTARA tokens by sending TARA tokens to the contract. The number of stTARA tokens minted is proportional to the amount of TARA sent. This amount must be greater than or equal to a specified `minDelegateAmount`.

- Users can burn their stTARA tokens to retrieve their original staked TARA tokens. The burned stTARA tokens are destroyed, and the equivalent amount of TARA tokens is transferred back to the user.

- The contract owner can also update the `minDelegateAmount`, which specifies the minimum amount of TARA required for minting stTARA tokens.

## Data Structure Definitions

### ERC20 Standard

The contract extends the ERC20 token standard and inherits its data structures and functions.

## Implemented Methods

### `constructor`

- **Description**: The constructor initializes the contract with the name "Staked TARA" and symbol "stTARA." It also sets the contract owner to the address of the deploying account.

- **Input Parameters**: None

### `setMinDelegateAmount`

- **Description**: Allows the contract owner to set the minimum amount of TARA required for minting stTARA tokens.

- **Input Parameters**:

  - `amount` (uint256): The new minimum amount of TARA required for minting stTARA tokens.

- **Modifiers**:
  - `onlyOwner`: Ensures that only the contract owner can call this function.

### `mint`

- **Description**: Allows users to mint stTARA tokens by sending TARA tokens to the contract. The number of stTARA tokens minted is proportional to the amount of TARA sent.

- **Input Parameters**:

  - None

- **Requirements**:

  - The amount of TARA sent must be greater than or equal to the `minDelegateAmount`.

- **Events**:
  - `Minted`: Emits an event to indicate that stTARA tokens have been minted for a user.

### `burn`

- **Description**: Allows users to burn stTARA tokens to retrieve their original staked TARA tokens. The burned stTARA tokens are destroyed, and the equivalent amount of TARA tokens is transferred back to the user.

- **Input Parameters**:

  - `amount` (uint256): The amount of stTARA tokens to be burned.

- **Requirements**:

  - The user must have a sufficient balance of stTARA tokens to burn.

- **Events**:
  - `Burned`: Emits an event to indicate that stTARA tokens have been burned, and TARA tokens have been returned to a user.

## Events

### `Minted` Event

- **Description**: This event is emitted when stTARA tokens are minted for a user.

- **Parameters**:
  - `user` (indexed address): The Ethereum address of the user receiving stTARA tokens.
  - `amount` (uint256): The amount of stTARA tokens minted.

### `Burned` Event

- **Description**: This event is emitted when stTARA tokens are burned, and the equivalent TARA tokens are returned to a user.

- **Parameters**:
  - `user` (indexed address): The Ethereum address of the user burning stTARA tokens.
  - `amount` (uint256): The amount of stTARA tokens burned.

### `setMinDelegateAmount` Event

- **Description**: This event is emitted when the contract owner updates the minimum delegate amount.

- **Parameters**:
  - `owner` (indexed address): The Ethereum address of the contract owner.
  - `newAmount` (uint256): The new minimum delegate amount.

---

This specification document outlines the business logic, data structure definitions, and implemented methods for the updated `stTARA` contract. It serves as a reference for understanding the functionality and usage of the contract on the Ethereum blockchain.
