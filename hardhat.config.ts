import * as dotenv from "dotenv";

import { HardhatUserConfig, task } from "hardhat/config";
import "@nomicfoundation/hardhat-chai-matchers";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "hardhat-contract-sizer";
import "@nomicfoundation/hardhat-foundry";
import "@openzeppelin/hardhat-upgrades";
import "solidity-docgen";
import { ethers } from "ethers";
dotenv.config();

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
    },
  },
  networks: {
    hardhat: {
      hardfork: "berlin",
      allowUnlimitedContractSize: true,
      accounts:
        process.env.TEST_KEY_1 !== undefined
          ? [
              {
                privateKey: process.env.TEST_KEY_1!,
                balance: ethers.parseEther("1000000000").toString(),
              },
              {
                privateKey: process.env.TEST_KEY_2!,
                balance: ethers.parseEther("1000000000").toString(),
              },
              {
                privateKey: process.env.TEST_KEY_3!,
                balance: ethers.parseEther("1000000000").toString(),
              },
              {
                privateKey: process.env.TEST_KEY_4!,
                balance: ethers.parseEther("1000000000").toString(),
              },
              {
                privateKey: process.env.TEST_KEY_5!,
                balance: ethers.parseEther("1000000000").toString(),
              },
              // {
              //   privateKey: process.env.TEST_KEY_6!,
              //   balance: ethers.utils.parseEther("1000000000").toString(),
              // },
              // {
              //   privateKey: process.env.TEST_KEY_7!,
              //   balance: ethers.utils.parseEther("1000000000").toString(),
              // },
            ]
          : [],
    },
    local: {
      hardfork: "berlin",
      url: "http://127.0.0.1:8545/",
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
      allowUnlimitedContractSize: true,
    },
    mainnet: {
      chainId: 841,
      hardfork: "berlin",
      url: process.env.TARA_MAINNET_URL || "",
      gas: 10000000,
      gasPrice: 10000000,
      allowUnlimitedContractSize: true,
    },
    testnet: {
      chainId: 842,
      hardfork: "berlin",
      url: process.env.TARA_TESTNET_URL || "",
      gas: 10000000,
      gasPrice: 10000000,
      allowUnlimitedContractSize: true,
    },
    devnet: {
      chainId: 843,
      hardfork: "berlin",
      url: process.env.TARA_DEVNET_URL || "",
      gas: 2100000,
      gasPrice: 8000000000,
      gasMultiplier: 20,
      allowUnlimitedContractSize: true,
    },
    ropsten: {
      url: process.env.ROPSTEN_URL || "",
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
      allowUnlimitedContractSize: true,
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  contractSizer: {
    alphaSort: true,
    disambiguatePaths: false,
    runOnCompile: true,
    strict: true,
    except: ["Test", "Mock", "Factory", "std"],
  },
  typechain: {
    outDir: "typechain",
    target: "ethers-v6",
  },
  docgen: {
    outputDir: "./docs",
    exclude: ["./contracts/mocks", "./contracts/test"],
  },
};

export default config;
