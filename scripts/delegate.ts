import { ethers } from "hardhat";
import * as dotenv from "dotenv";
import {
  BigNumberish,
  Contract,
  Typed,
  getAddress,
  parseEther,
  toBigInt,
} from "ethers";
import axios from "axios";
import ApyOracle from "../artifacts/contracts/ApyOracle.sol/ApyOracle.json";
import Lara from "../artifacts/contracts/Lara.sol/Lara.json";
import Dpos from "../artifacts/contracts/interfaces/IDPOS.sol/DposInterface.json";

dotenv.config();

async function main() {
  const privKey = process.env.DEPLOYER_KEY;
  const oracleAddress = "0x5a66Ab212bca20B7602d11bF49D56f93507B0FFB";
  const laraAddress = "0x91c6aCCFD788fe42cF8D96EB355B855F337c1950";
  const dposAddress = "0x00000000000000000000000000000000000000fe";
  if (privKey === undefined) {
    throw new Error("DEPLOYER_KEY not set");
  }
  const dataFeed = new ethers.Wallet(privKey, ethers.provider);
  console.log(`Deployer address: ${dataFeed.address}`);
  const laraAbi = ["function stake(uint256 amount) public payable"];
  const dposAbi = ["function delegate(address validator) external payable"];
  const oracle = new Contract(oracleAddress, ApyOracle.abi, dataFeed);
  const lara = new Contract(laraAddress, laraAbi, dataFeed);
  const dpos = new Contract(dposAddress, dposAbi, dataFeed);

  const nodes: string[] = [];
  nodes.push("0xc578bb5fc3dac3e96a8c4cb126c71d2dc9082817");
  nodes.push("0x5c9afb23fba3967ca6102fb60c9949f6a38cd9e8");
  nodes.push("0x5042fa2711fe547e46c2f64852fdaa5982c80697");
  nodes.push("0x6258d8f51ea17e873f69a2a978fe311fd95743dd");

  for (const node of nodes) {
    const isEligible = await dpos.isValidatorEligible(node);
    console.log(`Is ${node} eligible: ${isEligible}`);
  }
  const amount = parseEther("1000000");

  // delegate the same amount into Lara
  const tx = lara.interface.encodeFunctionData("stake", [
    Typed.uint256(amount * toBigInt(nodes.length)),
  ]);
  console.log(`Encoded tx: ${tx}`);
  const staked = await lara.stake(
    Typed.uint256(amount * toBigInt(nodes.length)),
    {
      value: amount,
      from: dataFeed.address,
    }
  );
  await staked.wait();
  const epochStarted = await lara.startEpoch();
  await epochStarted.wait();

  // delegate into DPOS
  for (const validator of nodes) {
    const delegate = await dpos.delegate(getAddress(validator), {
      value: amount,
    });
    await delegate.wait();
    console.log(`Delegated ${amount} into ${validator} via DPOS directly`);
  }
}
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
