import { ethers } from "hardhat";
import { ContractNames } from "../util/ContractNames";
import { ApyOracle, Lara, LaraFactory, MockDpos, StTARA } from "../typechain";
import {
  deployApyOracle,
  deployLaraFactory,
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
  let laraFactory: LaraFactory;
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
    laraFactory = await deployLaraFactory(
      dataFeed,
      await stTara.getAddress(),
      await mockDpos.getAddress(),
      await apyOracle.getAddress(),
      ethers.Wallet.createRandom().address
    );
    await stTara.setLaraFactory(await laraFactory.getAddress());
    v1InitialTotalStake = (await mockDpos.getValidator(v1.address)).total_stake;
    v2InitialTotalStake = (await mockDpos.getValidator(v2.address)).total_stake;
    v3InitialTotalStake = (await mockDpos.getValidator(v3.address)).total_stake;
  });

  describe("Getters/Setters", function () {
    it("should correctly set the initial state variables", async () => {
      expect(await laraFactory.apyOracle()).to.equal(
        await apyOracle.getAddress()
      );
      expect(await laraFactory.dposContract()).to.equal(
        await mockDpos.getAddress()
      );
      expect(await laraFactory.stTaraToken()).to.equal(
        await stTara.getAddress()
      );
      expect(await laraFactory.epochDuration()).to.equal(initialEpochDuration);
    });

    it("should not allow setting epoch duration stake capacity if not called by owner", async () => {
      const newEpochDuration = 14 * 24 * 60 * 60;
      await expect(laraFactory.setEpochDuration(newEpochDuration)).to.not.be
        .reverted;
      expect(await laraFactory.epochDuration()).to.equal(newEpochDuration);
    });

    it("should not allow setting max valdiator stake capacity if not called by owner", async () => {
      const [, randomAccount] = await ethers.getSigners();
      const initialMaxValidatorStakeCap = ethers.parseEther("80000000");
      expect(await laraFactory.maxValidatorStakeCapacity()).to.equal(
        initialMaxValidatorStakeCap
      );
      await expect(
        laraFactory
          .connect(randomAccount)
          .setMaxValidatorStakeCapacity(
            initialMaxValidatorStakeCap + toBigInt(10)
          )
      ).to.be.revertedWithCustomError(
        laraFactory,
        "OwnableUnauthorizedAccount"
      );
    });

    it("should allow setting max valdiator stake capacity if called by the owner", async () => {
      const initialMaxValidatorStakeCap = ethers.parseEther("80000000");
      expect(await laraFactory.maxValidatorStakeCapacity()).to.equal(
        initialMaxValidatorStakeCap
      );
      await expect(
        laraFactory.setMaxValidatorStakeCapacity(
          initialMaxValidatorStakeCap + toBigInt(10)
        )
      ).to.not.be.reverted;
      expect(await laraFactory.maxValidatorStakeCapacity()).to.equal(
        initialMaxValidatorStakeCap + toBigInt(10)
      );
    });

    it("should not allow setting min stake amount if not called by owner", async () => {
      const [, randomAccount] = await ethers.getSigners();
      expect(await laraFactory.minStakeAmount()).to.equal(initialMinStake);
      await expect(
        laraFactory
          .connect(randomAccount)
          .setMinStakeAmount(initialMinStake + toBigInt(10))
      ).to.be.revertedWithCustomError(stTara, "OwnableUnauthorizedAccount");
    });

    it("should allow setting min stake amount if called by owner", async () => {
      const initialMinStake = ethers.parseEther("1000");
      expect(await laraFactory.minStakeAmount()).to.equal(initialMinStake);
      await expect(
        laraFactory.setMinStakeAmount(initialMinStake + toBigInt(10))
      ).to.not.be.reverted;
      expect(await laraFactory.minStakeAmount()).to.equal(
        initialMinStake + toBigInt(10)
      );
    });
  });
});
