import { expect } from "chai";
import { ethers } from "hardhat";
import { NodeContinuityOracle } from "../typechain";
import { Signer } from "ethers";
import * as dotenv from "dotenv";

dotenv.config();

describe("NodeContinuityOracle", () => {
  let nodeOracle: NodeContinuityOracle;
  let dataFeedAddress: Signer;
  let secondSignerAddress: Signer;

  before(async () => {
    const signers = await ethers.getSigners();
    dataFeedAddress = signers[0];
    secondSignerAddress = signers[1];
    const NodeOracleFactory = await ethers.getContractFactory(
      "NodeContinuityOracle"
    );
    const nodeOracleProm = await NodeOracleFactory.deploy(
      await dataFeedAddress.getAddress() // Your data feed address
    );
    nodeOracle = await nodeOracleProm.deployed();
  });

  it("should deploy NodeOracle and set the data feed address", async () => {
    expect(await nodeOracle.getDataFeedAddress()).to.equal(
      await dataFeedAddress.getAddress()
    );
  });

  it("should update and retrieve node data", async () => {
    const nodeAddress = ethers.Wallet.createRandom().address; // Replace with a valid address
    const timestamp = Math.floor(Date.now() / 1000);
    const updatedNodeData = {
      dagsCount: 56311,
      lastDagTimestamp: 1692879072,
      lastPbftTimestamp: 1692877175,
      lastTransactionTimestamp: 1692879197,
      pbftCount: 8724,
      transactionsCount: 8893636,
    };

    await nodeOracle
      .connect(dataFeedAddress)
      .updateNodeStats(nodeAddress, timestamp, updatedNodeData);

    const registeredUpdateTimestamps = await nodeOracle.getNodeUpdateTimestamps(
      nodeAddress
    );
    expect(registeredUpdateTimestamps[0]).to.deep.equal(timestamp);
    const retrievedNodeData = await nodeOracle.getNodeStatsFrom(timestamp);
    expect(retrievedNodeData.pbftCount).to.deep.equal(
      updatedNodeData.pbftCount
    );
    expect(retrievedNodeData.dagsCount).to.deep.equal(
      updatedNodeData.dagsCount
    );
    expect(retrievedNodeData.lastPbftTimestamp).to.deep.equal(
      updatedNodeData.lastPbftTimestamp
    );
    expect(retrievedNodeData.lastDagTimestamp).to.deep.equal(
      updatedNodeData.lastDagTimestamp
    );
  });

  it("should throw unauthorized", async () => {
    const nodeAddress = ethers.Wallet.createRandom().address; // Replace with a valid address
    const timestamp = Math.floor(Date.now() / 1000);
    const updatedNodeData = {
      dagsCount: 56311,
      lastDagTimestamp: 1692879072,
      lastPbftTimestamp: 1692877175,
      lastTransactionTimestamp: 1692879197,
      pbftCount: 8724,
      transactionsCount: 8893636,
    };

    const updateData = nodeOracle
      .connect(secondSignerAddress)
      .updateNodeStats(nodeAddress, timestamp, updatedNodeData);

    expect(updateData).to.be.revertedWith(
      "ApyOracle: caller is not the data feed"
    );
  });
});
