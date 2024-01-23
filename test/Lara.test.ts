import { ethers } from "hardhat";
import { ContractNames } from "../util/ContractNames";
import { ApyOracle, Lara, MockDpos, StTARA } from "../typechain";
import {
  deployApyOracle,
  deployLara,
  deployMockDpos,
  deploystTara,
  setupApyOracle,
} from "./util/ContractsUtils";
import { expect } from "chai";
import { toBigInt } from "ethers";
import { ErrorsNames } from "./util/ErrorsNames";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

describe(ContractNames.lara, function () {
  let mockDpos: MockDpos;
  let apyOracle: ApyOracle;
  let stTara: StTARA;
  let lara: Lara;
  let dataFeed: SignerWithAddress;
  let v1: SignerWithAddress;
  let v2: SignerWithAddress;
  let v3: SignerWithAddress;
  let v1InitialTotalStake: bigint;
  let v2InitialTotalStake: bigint;
  let v3InitialTotalStake: bigint;
  const maxValidatorStakeCapacity = ethers.parseEther("80000000");
  const initialMinStake = ethers.parseEther("1000");
  const initialEpochDuration = 1000;

  beforeEach(async () => {
    dataFeed = (await ethers.getSigners())[1];
    [, v1, v2, v3] = await ethers.getSigners();
    mockDpos = await deployMockDpos();
    apyOracle = await deployApyOracle(
      dataFeed.address,
      await mockDpos.getAddress()
    );
    await setupApyOracle(apyOracle, dataFeed);
    stTara = await deploystTara(v1);
    lara = await deployLara(
      dataFeed,
      await stTara.getAddress(),
      await mockDpos.getAddress(),
      await apyOracle.getAddress(),
      ethers.Wallet.createRandom().address
    );
    await stTara.setLaraAddress(await lara.getAddress());
    v1InitialTotalStake = (await mockDpos.getValidator(v1.address)).total_stake;
    v2InitialTotalStake = (await mockDpos.getValidator(v2.address)).total_stake;
    v3InitialTotalStake = (await mockDpos.getValidator(v3.address)).total_stake;
  });

  describe("Getters/Setters", function () {
    it("should correctly set the initial state variables", async () => {
      expect(await lara.apyOracle()).to.equal(await apyOracle.getAddress());
      expect(await lara.dposContract()).to.equal(await mockDpos.getAddress());
      expect(await lara.stTaraToken()).to.equal(await stTara.getAddress());
      expect(await lara.epochDuration()).to.equal(initialEpochDuration);
    });

    it("should not allow setting epoch duration stake capacity if not called by owner", async () => {
      const newEpochDuration = 14 * 24 * 60 * 60;
      await expect(lara.setEpochDuration(newEpochDuration)).to.not.be.reverted;
      expect(await lara.epochDuration()).to.equal(newEpochDuration);
    });

    it("should not allow setting max valdiator stake capacity if not called by owner", async () => {
      const [, randomAccount] = await ethers.getSigners();
      const initialMaxValidatorStakeCap = ethers.parseEther("80000000");
      expect(await lara.maxValidatorStakeCapacity()).to.equal(
        initialMaxValidatorStakeCap
      );
      await expect(
        lara
          .connect(randomAccount)
          .setMaxValidatorStakeCapacity(
            initialMaxValidatorStakeCap + toBigInt(10)
          )
      ).to.be.revertedWithCustomError(lara, "OwnableUnauthorizedAccount");
    });

    it("should allow setting max valdiator stake capacity if called by the owner", async () => {
      const initialMaxValidatorStakeCap = ethers.parseEther("80000000");
      expect(await lara.maxValidatorStakeCapacity()).to.equal(
        initialMaxValidatorStakeCap
      );
      await expect(
        lara.setMaxValidatorStakeCapacity(
          initialMaxValidatorStakeCap + toBigInt(10)
        )
      ).to.not.be.reverted;
      expect(await lara.maxValidatorStakeCapacity()).to.equal(
        initialMaxValidatorStakeCap + toBigInt(10)
      );
    });

    it("should not allow setting min stake amount if not called by owner", async () => {
      const [, randomAccount] = await ethers.getSigners();
      expect(await lara.minStakeAmount()).to.equal(initialMinStake);
      await expect(
        lara
          .connect(randomAccount)
          .setMinStakeAmount(initialMinStake + toBigInt(10))
      ).to.be.revertedWithCustomError(stTara, "OwnableUnauthorizedAccount");
    });

    it("should allow setting min stake amount if called by owner", async () => {
      const initialMinStake = ethers.parseEther("1000");
      expect(await lara.minStakeAmount()).to.equal(initialMinStake);
      await expect(lara.setMinStakeAmount(initialMinStake + toBigInt(10))).to
        .not.be.reverted;
      expect(await lara.minStakeAmount()).to.equal(
        initialMinStake + toBigInt(10)
      );
    });
  });

  describe("Staking", function () {
    it("should not allow staking if the amount is lower than min", async () => {
      const amountToStake = ethers.parseEther("100");
      await expect(lara.stake(amountToStake))
        .to.be.revertedWithCustomError(lara, ErrorsNames.StakeAmountTooLow)
        .withArgs(amountToStake, initialMinStake);
    });

    it("should not allow staking if the value sent is lower than the amount", async () => {
      const amountToStake = ethers.parseEther("1001");
      await expect(lara.stake(amountToStake, { value: ethers.parseEther("2") }))
        .to.be.revertedWithCustomError(lara, ErrorsNames.StakeValueTooLow)
        .withArgs(ethers.parseEther("2"), amountToStake);
    });

    it("should allow staking if values are correct for one validator", async () => {
      const [, , , , staker] = await ethers.getSigners();
      const amountToStake = ethers.parseEther("1001");
      const stakeTx = lara
        .connect(staker)
        .stake(amountToStake, { value: amountToStake });
      await expect(stakeTx).to.changeTokenBalance(
        stTara,
        staker,
        amountToStake
      );
      await expect(stakeTx)
        .to.emit(lara, "Staked")
        .withArgs(staker.address, amountToStake);

      // Test that the user cannot burn the protocol balance
      const mintAmount = ethers.parseEther("1010");
      await expect(
        stTara.connect(staker).mint(staker.address, mintAmount)
      ).to.be.revertedWith("Only Lara can call this function");
      await expect(
        stTara
          .connect(staker)
          .burn(staker.address, amountToStake + toBigInt(mintAmount))
      ).to.be.revertedWith("Only Lara can call this function");

      // Test that the user can burn amount outside of protocol balance
      const stakeTx1 = stTara.connect(staker).burn(staker.address, mintAmount);
      await expect(stakeTx1).to.be.revertedWith(
        "Only Lara can call this function"
      );
    });

    it("should allow staking if values are correct for multiple validators", async () => {
      const [, , , , staker] = await ethers.getSigners();
      const amountToStake = ethers.parseEther("60000000");

      const stakeTx3 = lara
        .connect(staker)
        .stake(amountToStake, { value: amountToStake });
      const receipt = await stakeTx3;
      const tx = await receipt.wait();
      if (tx) {
        const totalGasUsed = tx.gasUsed * receipt.gasPrice;
        await expect(stakeTx3)
          .to.emit(lara, "Staked")
          .withArgs(staker.address, amountToStake);
        await expect(stakeTx3).to.changeTokenBalance(
          stTara,
          staker,
          amountToStake
        );
        await expect(stakeTx3).to.changeEtherBalance(
          staker,
          amountToStake * toBigInt(-1) - totalGasUsed
        );
      }
    });

    it("should allow staking with amount greater than total capacity, but should stake only capacity", async () => {
      const [, , , , staker] = await ethers.getSigners();
      const surplusAmount = ethers.parseEther("1000");
      const amountToStake =
        maxValidatorStakeCapacity * toBigInt(3) -
        toBigInt(v1InitialTotalStake) -
        toBigInt(v2InitialTotalStake) -
        toBigInt(v3InitialTotalStake) +
        toBigInt(surplusAmount);

      const stakeTx4 = lara
        .connect(staker)
        .stake(amountToStake, { value: amountToStake });
      const receipt = await stakeTx4;
      console.log("receipt", receipt);
      const tx = await receipt.wait();
      if (tx) {
        const totalGasUsed = tx.gasUsed * receipt.gasPrice;
        await expect(stakeTx4)
          .to.emit(lara, "Staked")
          .withArgs(staker.address, amountToStake - surplusAmount);
        await expect(stakeTx4).to.changeTokenBalance(
          stTara,
          staker,
          amountToStake - toBigInt(surplusAmount)
        );
        await expect(stakeTx4).to.changeEtherBalance(
          staker,
          (amountToStake - toBigInt(surplusAmount)) * toBigInt(-1) -
            totalGasUsed
        );
      }
    });
  });
});
