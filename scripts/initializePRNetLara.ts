import { ethers } from "hardhat";
import * as dotenv from "dotenv";
import { BigNumberish, Contract, toBigInt, Wallet,Typed, parseEther } from "ethers";
import axios from "axios";

dotenv.config();

const USER_WALLET_COUNT = 200;
const VALIDATOR_COUNT = 10;
const VALIDATOR_ALLOCATION = 40000000;  // Use BigInt instead of `parseUnits(`
const SOLO_VALIDATOR_ALLOCATION = 40000000;
const MIN_VALIDATOR_ALLOCATION = 500000;
const MAX_TARA = 800000000;
const MAX_TARA_USERS = 716000000;
const PERC_INITIAL_USER_DISTRIBUTION = 0.6;

async function main() {
    const genesisPrivateKey = process.env.DEPLOYER_KEY;
    if (genesisPrivateKey === undefined) {
      throw new Error("Genesis key not set");
    }

    const genesisWallet = new ethers.Wallet(genesisPrivateKey, ethers.provider);

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

    // Distribute Tara to validator wallets
    for (let i = 0; i < validatorWallets.length; i++) {
        const wallet = validatorWallets[i];
        if (i === 0 || i === 1) {
            await transferNativeTokens(genesisWallet, wallet.address, parseEther(`${SOLO_VALIDATOR_ALLOCATION}`));
        } else {
            await transferNativeTokens(genesisWallet, wallet.address, parseEther(`${MIN_VALIDATOR_ALLOCATION}`));
        }

    }


}

async function transferNativeTokens(senderWallet: Wallet, recipientAddress: string, amount: BigNumberish) {
    const transaction = {
        to: recipientAddress,
        value: amount
    };

    // Send the transaction and await confirmation
    await senderWallet.sendTransaction(transaction);
}

async function generateWallets(count: number): Promise<{ address: string; isValidator: boolean; }[]> {    const wallets = [];
    for (let i = 0; i < count; i++) {
        const wallet = ethers.Wallet.createRandom();
        const isValidator = i < VALIDATOR_COUNT;
        wallets.push({ address: wallet.address, isValidator });
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


