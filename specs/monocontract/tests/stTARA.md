# Test Specifications - stTARA Contract

The test specifications outline the unit tests for the `stTARA` contract, which is a token contract based on the ERC20 standard. These tests ensure the correct functionality of the contract's core features.

## Test: Correct Initial Balances

- **Description**: This test verifies that the initial balances of the minter and burner accounts are set correctly during setup.

- **Expected Behavior**:
  - The minter account has an initial balance of 1001 Tara.
  - The burner account has an initial balance of 1001 Tara.

## Test: Minting stTARA Tokens

- **Description**: This test verifies that stTARA tokens can be minted when the `minDelegateAmount` is met.

- **Steps**:

  1. Set the `minDelegateAmount` to 1000 Tara.
  2. Attempt to mint 999 Tara worth of stTARA tokens.
  3. Attempt to mint 1000 Tara worth of stTARA tokens.

- **Expected Behavior**:
  - The first minting attempt is reverted with the message "Needs to be at least equal to minDelegateAmount."
  - The second minting attempt is successful.
  - The minter's stTARA balance is updated accordingly.
  - An event is emitted for the successful minting.

## Test: Backswapping stTARA Tokens for TARA Tokens

- **Description**: This test verifies that stTARA tokens can be backswapped for TARA tokens.

- **Steps**:

  1. Mint 1000 Tara worth of stTARA tokens.
  2. Burn 1000 stTARA tokens.

- **Expected Behavior**:
  - The stTARA tokens are successfully minted.
  - The stTARA tokens are successfully burned.
  - The burner's stTARA balance is updated to 0.
  - The burner's Tara balance is increased.

## Test: Transferring stTARA Tokens

- **Description**: This test verifies that stTARA tokens can be transferred between accounts.

- **Steps**:

  1. Mint 1000 Tara worth of stTARA tokens.
  2. Transfer 1000 stTARA tokens to another account.

- **Expected Behavior**:
  - The stTARA tokens are successfully minted.
  - The stTARA tokens are successfully transferred.
  - The minter's stTARA balance is reduced.
  - The recipient's stTARA balance is increased.

## Test: Allowing Token Transfer with Approval

- **Description**: This test verifies that token transfers are allowed if the spender has been approved by the owner.

- **Steps**:

  1. Mint 1000 Tara worth of stTARA tokens.
  2. Approve another account to spend 1000 stTARA tokens.
  3. Transfer the approved amount to a third account.

- **Expected Behavior**:
  - The stTARA tokens are successfully minted.
  - The spender is approved to spend a certain amount.
  - The approved amount is successfully transferred to the third account.
  - The spender's stTARA allowance is updated accordingly.

## Test: Unauthorized Token Transfer

- **Description**: This test verifies that unauthorized token transfers are prevented if the spender has not been approved.

- **Steps**:

  1. Attempt to transfer stTARA tokens without approval.

- **Expected Behavior**:
  - The transfer transaction is reverted with the message "ERC20: insufficient allowance."

## Test: Backswapping by a Non-Burner

- **Description**: This test verifies that a non-burner account cannot backswap stTARA tokens for TARA tokens.

- **Steps**:

  1. Mint 1000 Tara worth of stTARA tokens.
  2. Attempt to burn stTARA tokens from a non-burner account.

- **Expected Behavior**:
  - The burn transaction is reverted with the message "Insufficient stTARA balance."

## Test: Backswapping by a Burner

- **Description**: This test verifies that a burner account can backswap stTARA tokens for TARA tokens.

- **Steps**:

  1. Mint 1000 Tara worth of stTARA tokens.
  2. Burn 1000 stTARA tokens from a burner account.

- **Expected Behavior**:
  - The stTARA tokens are successfully minted.
  - The stTARA tokens are successfully burned.
  - The burner's stTARA balance is updated to 0.
  - The burner's Tara balance is increased.
  - An event is emitted for the successful burning.

---

This test specifications document provides a clear overview of the tests conducted on the `stTARA` contract. Each test case describes its purpose, steps, expected behavior, and outcomes. These tests ensure the correctness and security of the contract's functionality.
