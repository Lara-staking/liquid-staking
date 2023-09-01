# Test Specifications - NodeContinuityOracle Contract

The test specifications outline the unit tests for the `NodeContinuityOracle` contract, which is responsible for updating and retrieving node continuity data. These tests ensure the correct functionality of the contract's core features.

## Test: Deploy NodeContinuityOracle and Set Data Feed Address

- **Description**: This test verifies that the `NodeContinuityOracle` contract is successfully deployed and the data feed address is correctly set during deployment.

- **Expected Behavior**:
  - The contract deploys successfully.
  - The data feed address is correctly set.

## Test: Update and Retrieve Node Data

- **Description**: This test verifies that node data can be updated by the data feed address and retrieved correctly.

- **Steps**:

  1. Deploy the `NodeContinuityOracle` contract.
  2. Generate a random node address.
  3. Generate a random timestamp.
  4. Update the node data using the data feed address.
  5. Retrieve the registered update timestamps for the node.
  6. Retrieve the node data for the specified timestamp.

- **Expected Behavior**:
  - The node data is successfully updated.
  - The registered update timestamps for the node include the new timestamp.
  - The retrieved node data matches the updated values.

## Test: Unauthorized Update Node Data

- **Description**: This test verifies that an unauthorized address cannot update node data.

- **Steps**:

  1. Deploy the `NodeContinuityOracle` contract.
  2. Generate a random node address.
  3. Generate a random timestamp.
  4. Attempt to update the node data using an unauthorized address.

- **Expected Behavior**:
  - The update transaction should be reverted with the message "ApyOracle: caller is not the data feed."

---

This test specifications document provides a clear overview of the tests conducted on the `NodeContinuityOracle` contract. Each test case describes its purpose, steps, expected behavior, and outcomes. These tests ensure the correctness and security of the contract's functionality.
