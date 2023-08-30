import { expect } from "chai";
import { ethers } from "hardhat";
import { ApyOracle } from "../typechain";
import { Signer } from "ethers";
import * as dotenv from "dotenv";

dotenv.config();

describe("ApyOracle", () => {
  let apyOracle: ApyOracle;
  let dataFeedAddress: Signer;
  let secondSignerAddress: Signer;

  before(async () => {
    const signers = await ethers.getSigners();
    dataFeedAddress = signers[0];
    secondSignerAddress = signers[1];
    const ApyOracleFactory = await ethers.getContractFactory("ApyOracle");
    const apyOracleProm = await ApyOracleFactory.deploy(
      await dataFeedAddress.getAddress() // Your data feed address
    );
    apyOracle = await apyOracleProm.deployed();
  });

  it("should deploy ApyOracle and set the data feed address", async () => {
    expect(await apyOracle.getDataFeedAddress()).to.equal(
      await dataFeedAddress.getAddress()
    );
  });

  it("should update and retrieve node data", async () => {
    const nodeAddress = ethers.Wallet.createRandom().address; // Replace with a valid address
    const updatedNodeData = {
      pbftCount: 5555,
      rank: 1,
      account: ethers.Wallet.createRandom().address,
      apy: 500, // Example APY value
      fromBlock: 1000,
      toBlock: 2000,
    };

    await apyOracle
      .connect(dataFeedAddress)
      .updateNodeData(nodeAddress, updatedNodeData);

    const retrievedNodeData = await apyOracle.getNodeData(nodeAddress);
    expect(retrievedNodeData.rank).to.deep.equal(updatedNodeData.rank);
    expect(retrievedNodeData.pbftCount).to.deep.equal(
      updatedNodeData.pbftCount
    );
    expect(retrievedNodeData.apy).to.deep.equal(updatedNodeData.apy);
  });

  it("should throw unauthorized", async () => {
    const nodeAddress = ethers.Wallet.createRandom().address; // Replace with a valid address
    const updatedNodeData = {
      pbftCount: 5555,
      rank: 1,
      account: ethers.Wallet.createRandom().address,
      apy: 500, // Example APY value
      fromBlock: 1000,
      toBlock: 2000,
    };

    const updateData = apyOracle
      .connect(secondSignerAddress)
      .updateNodeData(nodeAddress, updatedNodeData);

    expect(updateData).to.be.revertedWith(
      "ApyOracle: caller is not the data feed"
    );
  });
});
