import { expect } from "chai";
import * as dotenv from "dotenv";
import { ethers } from "hardhat";
import { ContractNames } from "../util/ContractNames";
import { deployApyOracle, deployMockDpos } from "./util/ContractsUtils";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { MockDpos } from "../typechain/contracts/mocks";
import { ApyOracle } from "../typechain/contracts";

dotenv.config();

describe(ContractNames.apyOracle, () => {
  let apyOracle: ApyOracle;
  let dpos: MockDpos;
  let dataFeedAddress: SignerWithAddress;
  let secondSignerAddress: SignerWithAddress;

  before(async () => {
    const signers = await ethers.getSigners();
    dataFeedAddress = signers[0];
    secondSignerAddress = signers[1];
    dpos = await deployMockDpos();
    apyOracle = await deployApyOracle(
      dataFeedAddress.address,
      await dpos.getAddress()
    );
  });

  it("should deploy ApyOracle and set the data feed address", async () => {
    const datafeedAddress = await apyOracle.getDataFeedAddress();
    expect(dataFeedAddress.address).to.equal(datafeedAddress);
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
      rating: 997,
    };

    await apyOracle
      .connect(dataFeedAddress)
      .updateNodeData(nodeAddress, updatedNodeData);

    const retrievedNodeData = await apyOracle.getNodeData(nodeAddress);
    expect(retrievedNodeData.rank).to.deep.equal(updatedNodeData.rank);
    expect(retrievedNodeData.rating).to.deep.equal(updatedNodeData.rating);
    expect(retrievedNodeData.apy).to.deep.equal(updatedNodeData.apy);
  });

  it("should throw unauthorized", async () => {
    const nodeAddress = ethers.Wallet.createRandom().address; // Replace with a valid address
    const updatedNodeData = {
      rating: 5555,
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
