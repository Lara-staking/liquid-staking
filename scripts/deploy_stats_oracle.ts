// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";
import * as dotenv from "dotenv";

dotenv.config();

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const Oracle = await ethers.getContractFactory("NodeContinuityOracle");
  const privKey = process.env.MAINNET_PRIV_KEY!;
  if (privKey === undefined) {
    throw new Error("MAINNET_PRIV_KEY not set");
  }
  const dataFeed = new ethers.Wallet(privKey, ethers.provider);
  const oracle = await Oracle.connect(dataFeed).deploy(
    await dataFeed.getAddress()
  );

  await oracle.deployed();

  console.log("Oracle deployed to:", oracle.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
