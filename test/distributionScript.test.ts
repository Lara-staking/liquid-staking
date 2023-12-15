import { ethers } from "hardhat";
import { expect } from "chai";
import * as dotenv from "dotenv";
import { BigNumberish, Contract, toBigInt, Wallet,Typed, parseEther, HDNodeWallet, Signer } from "ethers";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { ApyOracle, Lara, MockDpos, StTARA } from "../typechain";
import {
  deployApyOracle,
  deployLara,
  deployMockDpos,
  deploystTara,
  setupApyOracle,
} from "./util/ContractsUtils";

const USER_WALLET_COUNT = 200;
const VALIDATOR_COUNT = 10;
const VALIDATOR_ALLOCATION = 40000000;  // Use BigInt instead of `parseUnits(`
const SOLO_VALIDATOR_ALLOCATION = 40000000;
const MIN_VALIDATOR_ALLOCATION = 500000;
const MAX_TARA = 800000000;
const MAX_TARA_USERS = 716000000;
const PERC_INITIAL_USER_DISTRIBUTION = 0.6;

async function transferNativeTokens(senderWallet: Wallet | SignerWithAddress, recipientAddress: string, amount: BigNumberish) {
    const transaction = {
        to: recipientAddress,
        value: amount
    };

    // Send the transaction and await confirmation
    await senderWallet.sendTransaction(transaction);
}

async function generateWallets(count: number): Promise<{ wallet: Signer, address: string; isValidator: boolean; }[]> {    
    const wallets = [];

    for (let i = 0; i < count; i++) {
        let wallet: Signer = ethers.Wallet.createRandom(ethers.provider);
        const isValidator = i < VALIDATOR_COUNT;
        let walletAddress = await wallet.getAddress();
        wallets.push({ wallet: wallet, address: walletAddress, isValidator });
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
        let maxForThisWallet: BigInt = remainingAmount / BigInt(count - i);
        // let maxForThisWallet: BigInt = toBigInt(Number(remainingAmount) / (count - i));
        let randomAmount = BigInt(Math.floor(Number(maxForThisWallet) * Math.random()));
        amounts[i] = randomAmount;
        remainingAmount -= randomAmount;
    }
    
    return amounts;
}

async function randomTransferAndStake(stakerWallet: Wallet | SignerWithAddress, userWallets: WalletInfo[] ,  laraContract: Lara) {
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
    await transferNativeTokens(stakerWallet, randomUser.address, randomAmount);
    let randomUserBalanceAfter = await ethers.provider.getBalance(randomUser.address);

    // Subtract some to allow for gas
    let amountToStake = randomAmount - ethers.parseEther("1");
    await laraContract.connect(randomUser.wallet).stake(amountToStake, { value: amountToStake });
}

export interface WalletInfo {
    wallet: Signer;
    address: string;
    isValidator: boolean;
}

describe("Token Distribution", function () {
    let genesisWallet: SignerWithAddress;
    let userWallets: WalletInfo[];
    let validatorWallets: WalletInfo[];
    let v1: SignerWithAddress;
    let v2: SignerWithAddress;
    let v3: SignerWithAddress;
    let mockDpos: MockDpos;
    let apyOracle: ApyOracle;
    let stTara: StTARA;
    let lara: Lara;
    let dataFeed: SignerWithAddress;
    let userAllocations: BigInt[];

    beforeEach(async function () {
        // Simulate Genesis Wallet
        [genesisWallet, v1, v2, v3] = await ethers.getSigners();
        
        //Setup Wallets
        userWallets = await generateWallets(USER_WALLET_COUNT);
        validatorWallets = await generateWallets(VALIDATOR_COUNT);
        for (let i = 0; i < validatorWallets.length; i++) {
            const wallet = validatorWallets[i];
            if (i === 0 || i === 1) {
                await transferNativeTokens(genesisWallet, wallet.address, parseEther(`${SOLO_VALIDATOR_ALLOCATION}`));
                let balance= await ethers.provider.getBalance(wallet.address);
                expect(balance).to.be.equal(parseEther(`${SOLO_VALIDATOR_ALLOCATION}`));
            } else {
                await transferNativeTokens(genesisWallet, wallet.address, parseEther(`${MIN_VALIDATOR_ALLOCATION}`));
                let balance= await ethers.provider.getBalance(wallet.address);
                expect(balance).to.be.equal(parseEther(`${MIN_VALIDATOR_ALLOCATION}`));
            }

        }

        userAllocations = distributeAmounts(MAX_TARA_USERS, USER_WALLET_COUNT);
        for (let i = 0; i < userWallets.length; i++) {
            const wallet = userWallets[i];
            const amount = userAllocations[i];
            transferNativeTokens(genesisWallet, wallet.address, toBigInt(Number(amount)));
        }
        
        //Deploy Contracts
        mockDpos = await deployMockDpos();
        apyOracle = await deployApyOracle(
                genesisWallet.address,
                await mockDpos.getAddress()
        );
        await setupApyOracle(apyOracle, genesisWallet);

        stTara = await deploystTara(v1);
        lara = await deployLara(
            await stTara.getAddress(),
            await mockDpos.getAddress(),
            await apyOracle.getAddress(),
            ethers.Wallet.createRandom().address
        );
        await stTara.setLaraAddress(await lara.getAddress());
    });

    it("should distribute funds to validators", async function () {
        // Simulate distribution
        for (let i = 0; i < validatorWallets.length; i++) {
            const wallet = validatorWallets[i];
            if (i === 0 || i === 1) {
                let balance= await ethers.provider.getBalance(wallet.address);
                expect(balance).to.be.equal(parseEther(`${SOLO_VALIDATOR_ALLOCATION}`));
            } else {
                let balance= await ethers.provider.getBalance(wallet.address);
                expect(balance).to.be.equal(parseEther(`${MIN_VALIDATOR_ALLOCATION}`));
            }
    
        }
    });

    it("should distribute user tokens without exceeding the max limit", async function () {
        const totalDistributed = userAllocations.reduce((acc, val) => Number(acc) + Number(val), 0);
        expect(totalDistributed).to.be.lessThanOrEqual(MAX_TARA_USERS);
    });

    it("should stake all available tara to Lara from user addresses", async function () {
        for (let i = 0; i < userWallets.length; i++) {
            let staker = userWallets[i].wallet;
            let stakerAddress = userWallets[i].address;
            let stakerBalance = await ethers.provider.getBalance(stakerAddress);
            const gasBuffer = ethers.parseEther("1");
            stakerBalance = stakerBalance - gasBuffer;

            const stakedAmountBefore = await lara.stakedAmounts(stakerAddress);
            console.log("🚀 ~ file: distributionScript.test.ts:213 ~ stakedAmountBefore:", stakedAmountBefore)
            const stakeTx = lara
              .connect(staker)
              .stake(stakerBalance, { value: stakerBalance });

            //FAILS HERE, but works if using validatorWallets instead
            await expect(stakeTx).to.changeTokenBalance(
              stTara,
              staker,
              stakerBalance
            );
            await expect(stakeTx)
              .to.emit(lara, "Staked")
              .withArgs(stakerAddress, stakerBalance);
        
            const stakedAmountAfter = await lara.stakedAmounts(stakerAddress);
            console.log("🚀 ~ file: distributionScript.test.ts:227 ~ stakedAmountAfter:", stakedAmountAfter)
            expect(stakedAmountAfter).to.equal(
              stakedAmountBefore + toBigInt(stakerBalance)
            );
        }
    });

    
    it("should randomly transfer and stake tokens", async function () {
        this.timeout(0); // Disable Mocha timeout
        const someNumberOfIterations = 50;

        async function simulateRandomActions() {
            for (let i = 0; i < someNumberOfIterations; i++) {
                await randomTransferAndStake(genesisWallet, userWallets, lara);

                // Wait for a random period
                console.log("Waiting for a random period before the next action");
                await new Promise(resolve => setTimeout(resolve, Math.random() * 5));
                console.log("Finished waiting for a random period");
            }
        }

        await simulateRandomActions();
    });


});

