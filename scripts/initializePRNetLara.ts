import { ethers } from "hardhat";
import * as dotenv from "dotenv";
import {  BigNumberish, Contract, toBigInt, Wallet,Typed, parseEther, HDNodeWallet } from "ethers";
import axios from "axios";
import {
  deployApyOracle,
  deployLara,
  deployMockDpos,
  deploystTara,
  setupApyOracle,
} from "./util/ContractsUtils";
import { SignerWithAddress, HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { ApyOracle, Lara, MockDpos, StTARA } from "../typechain";


dotenv.config();

const USER_WALLET_COUNT = 200;
const VALIDATOR_COUNT = 10;
const VALIDATOR_ALLOCATION = 40000000;  // Use BigInt instead of `parseUnits(`
const SOLO_VALIDATOR_ALLOCATION = 40000000;
const MIN_VALIDATOR_ALLOCATION = 500000;
const MAX_TARA = 800000000;
const MAX_TARA_USERS = 716000000;
const PERC_INITIAL_USER_DISTRIBUTION = 0.6;
const NUM_USER_WALLET_DISTRIBUTION_ITERATIONS = 50;

export interface WalletInfo {
    wallet: HDNodeWallet;
    address: string;
    isValidator: boolean;
}

export type WalletType = HDNodeWallet | Wallet | SignerWithAddress | HardhatEthersSigner;

async function main() {
    const genesisPrivateKey = process.env.DEPLOYER_KEY;
    if (genesisPrivateKey === undefined) {
      throw new Error("Genesis key not set");
    }

    const genesisWallet: Wallet = new ethers.Wallet(genesisPrivateKey, ethers.provider);

    // Generate user and validator wallets
    const userWallets = await generateWallets(USER_WALLET_COUNT);
    const validatorWallets = await generateWallets(VALIDATOR_COUNT);

    // Usage in the main function
    const userAllocations = distributeAmounts(MAX_TARA_USERS, USER_WALLET_COUNT);

    // Distribute Tara to user wallets
    for (let i = 0; i < userWallets.length; i++) {
        const wallet = userWallets[i];
        const amount = userAllocations[i];
        await transferNativeTokens(genesisWallet, wallet.address, toBigInt(Number(amount)));
    }

    // // Distribute Tara to validator wallets
    // for (let i = 0; i < validatorWallets.length; i++) {
    //     const wallet = validatorWallets[i];
    //     if (i === 0 || i === 1) {
    //         await transferNativeTokens(genesisWallet, wallet.address, parseEther(`${SOLO_VALIDATOR_ALLOCATION}`));
    //     } else {
    //         await transferNativeTokens(genesisWallet, wallet.address, parseEther(`${MIN_VALIDATOR_ALLOCATION}`));
    //     }
    // }

    const v1 = validatorWallets[0].wallet;
    const v2 = validatorWallets[1].wallet;

    //Deploy Contracts
    const mockDpos: MockDpos = await deployMockDpos([v1, v2]);
    const apyOracle: ApyOracle = await deployApyOracle(
            genesisWallet.address,
            await mockDpos.getAddress()
    );
    await setupApyOracle(apyOracle, genesisWallet);
    const stTara: StTARA = await deploystTara(v1);
    const lara: Lara = await deployLara(
        await stTara.getAddress(),
        await mockDpos.getAddress(),
        await apyOracle.getAddress(),
        ethers.Wallet.createRandom().address
    );
    await stTara.setLaraAddress(await lara.getAddress());

    //Validators register with DPOS
    await userStakeAvailableTokens(userWallets, lara);

    await randomTransferAndStake(genesisWallet, userWallets, lara);

}

async function transferNativeTokens(senderWallet: HDNodeWallet | Wallet | SignerWithAddress, recipientAddress: string, amount: BigNumberish) {
    const transaction = {
        to: recipientAddress,
        value: amount
    };

    await senderWallet.sendTransaction(transaction);
}

async function generateWallets(count: number): Promise<{ wallet: HDNodeWallet, address: string; isValidator: boolean; }[]> {    const wallets = [];
    for (let i = 0; i < count; i++) {
        const wallet = ethers.Wallet.createRandom(ethers.provider);
        const isValidator = i < VALIDATOR_COUNT;
        wallets.push({ wallet: wallet, address: wallet.address, isValidator });
    }
    return wallets;
}


function distributeAmounts(totalAmount: number, count: number): BigInt[] {
    let amounts = new Array<BigInt>(count).fill(BigInt(0));
    let remainingAmount = toBigInt(totalAmount);
    
    for (let i = 0; i < count; i++) {
        if (i === count - 1) {
            amounts[i] = toBigInt(remainingAmount);
            break;
        }
        
        let maxForThisWallet: BigInt = toBigInt(Number(remainingAmount) / (count - i));
        let randomAmount = BigInt(Math.floor(Number(maxForThisWallet) * Math.random()));
        amounts[i] = randomAmount;
        remainingAmount -= randomAmount;
    }
    
    return amounts;
}

async function randomTransferAndStake(genesisWallet: WalletType, userWallets: WalletInfo[] ,  laraContract: Lara) {
    const minAmount = ethers.parseEther("1000");
    let randomAmount;
    do {
        randomAmount = ethers.parseEther(
            (Math.random() * (0.4 * MAX_TARA_USERS / USER_WALLET_COUNT)).toString()
        );
    } while (randomAmount < minAmount);

    // Random user wallet to receive the transfer
    const randomUser = userWallets[Math.floor(Math.random() * userWallets.length)];

    // Transfer tokens
    let minStakeAmount = await laraContract.minStakeAmount();
    let randomUserBalanceBefore = await ethers.provider.getBalance(randomUser.address);
    await transferNativeTokens(genesisWallet, randomUser.address, randomAmount);
    let randomUserBalanceAfter = await ethers.provider.getBalance(randomUser.address);

    // Subtract some to allow for gas
    let amountToStake = randomAmount - ethers.parseEther("1");
    await laraContract.connect(randomUser.wallet).stake(amountToStake, { value: amountToStake });
    

    await simulateRandomActions(genesisWallet, userWallets, laraContract);
}

async function simulateRandomActions(genesisWallet: WalletType, userWallets: WalletInfo[], lara: Lara) {
    
    for (let i = 0; i < NUM_USER_WALLET_DISTRIBUTION_ITERATIONS; i++) {
        await randomTransferAndStake(genesisWallet, userWallets, lara);

        // Wait for a random period
        console.log("Waiting for a random period before the next action");
        await new Promise(resolve => setTimeout(resolve, Math.random() * 5));
        console.log("Finished waiting for a random period");
    }
}


async function userStakeAvailableTokens(userWallets: WalletInfo[], lara: Lara) {
    for (let i = 0; i < userWallets.length; i++) {
        let staker = userWallets[i].wallet;
        let stakerBalance = await ethers.provider.getBalance(staker.address);
        const gasBuffer = ethers.parseEther("1");
        stakerBalance = stakerBalance - gasBuffer;

        const stakedAmountBefore = await lara.stakedAmounts(staker.address);
        const stakeTx = await lara
          .connect(staker)
          .stake(stakerBalance, { value: stakerBalance });

        await stakeTx.wait();

        const stakedAmountAfter = await lara.stakedAmounts(staker.address);
        if (stakedAmountAfter - stakedAmountBefore > stakerBalance) {
          throw new Error("Staked amount does not match");
        } else {
            console.log(`Staked amount matches, wallet ${staker}, staked ${stakedAmountAfter - stakedAmountBefore} TARA`);
        }
    }
}