// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";
import * as dotenv from "dotenv";
import { BigNumberish, Contract } from "ethers";
import axios from "axios";
import ApyOracle from "../artifacts/contracts/ApyOracle.sol/ApyOracle.json";

dotenv.config();

interface NodeData {
  account: string;
  rank: BigNumberish;
  rating: BigNumberish;
  apy: BigNumberish;
  fromBlock: BigNumberish;
  toBlock: BigNumberish;
}

async function main() {
  const privKey = process.env.DEPLOYER_KEY;
  const oracleAddress = "0xE17B595748E6207A9416d9FEB07139cA437054bf";
  if (privKey === undefined) {
    throw new Error("DEPLOYER_KEY not set");
  }
  const dataFeed = new ethers.Wallet(privKey, ethers.provider);
  console.log(`Deployer address: ${dataFeed.address}`);
  const oracle = new Contract(oracleAddress, ApyOracle.abi, dataFeed);

  const validators = await getValidatorsListFromTestnetIndexer();
  console.log(`Got ${validators.length} validators from indexer`);
  // update validators in oracle
  const dataFeedAddress = await oracle.getDataFeedAddress();
  console.log(`Data feed address: ${dataFeedAddress}`);
  const nodeCount = await oracle.getNodeCount();
  console.log(`Current node count: ${nodeCount}`);

  // const count = toBigInt(validators.length);
  // const updateNodeCount = await oracle.updateNodeCount(count, {
  //   gasLimit: 1000000,
  //   gasPrice: ethers.parseUnits("100", "gwei"),
  // });
  // // await updateNodeCount.wait();

  for (const validator of validators) {
    const updateNode = await oracle.updateNodeData(
      ethers.getAddress(validator.account),
      validator,
      {
        gasLimit: 300000,
        gasPrice: ethers.parseUnits("100", "wei"),
      }
    );
    await updateNode.wait();
    console.log(`Updated ${validator.account}`);
  }
}

async function getValidatorsListFromTestnetIndexer(): Promise<NodeData[]> {
  const response = await axios.get(
    `https://indexer.testnet.explorer.taraxa.io/validators?limit=100&orderBy=rank`
  );
  const validatorsList = response.data.data;
  const structuredVaidators: NodeData[] = [];
  for (const validator of validatorsList) {
    structuredVaidators.push({
      account: validator.address,
      rank: ethers.toBigInt(validator.rank),
      rating: ethers.toBigInt(validator.pbftCount),
      apy: ethers.toBigInt(Math.round(validator.yield * 10000)),
      fromBlock: ethers.toBigInt(0),
      toBlock: ethers.toBigInt(0),
    });
  }
  return structuredVaidators;
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
