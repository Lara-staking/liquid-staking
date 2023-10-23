import { expect } from "chai";
import { ethers } from "hardhat";
import { NodeContinuityOracle } from "../typechain";
import * as dotenv from "dotenv";
import { ContractsNames } from "../util/ContractsNames";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { deployNodeContinuityOracle } from "./util/ContractsUtils";

dotenv.config();

describe(ContractsNames.nodeContinuityOracle, () => {
  let nodeOracle: NodeContinuityOracle;
  let dataFeed: SignerWithAddress;
  let secondSignerAddress: SignerWithAddress;

  before(async () => {
    const signers = await ethers.getSigners();
    dataFeed = signers[0];
    secondSignerAddress = signers[1];
    nodeOracle = await deployNodeContinuityOracle(dataFeed.address);
  });

  it("should deploy NodeOracle and set the data feed address", async () => {
    expect(await nodeOracle.getDataFeedAddress()).to.equal(
      dataFeed.address
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
      .connect(dataFeed)
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
