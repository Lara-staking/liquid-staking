import { ethers } from "hardhat";
import { expect } from "chai";
import { toBigInt } from "ethers";
import { ErrorsNames } from "./util/ErrorsNames";
import {
  deployApyOracle,
  deployLaraFactory,
  deploystTara,
} from "./util/ContractsUtils";
import { ContractNames } from "../util/ContractNames";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { ApyOracle, LaraFactory, StTARA } from "../typechain";

describe(ContractNames.stTara, () => {
  let stTara: StTARA;
  let apyOracle: ApyOracle;
  let laraFactory: LaraFactory;
  let initialMinDepositAmount: bigint;
  let minter: SignerWithAddress;
  let burner: SignerWithAddress;
  let recipient: SignerWithAddress;
  let finalTarget: SignerWithAddress;

  beforeEach(async () => {
    initialMinDepositAmount = ethers.parseEther("1000");
    const signers = await ethers.getSigners();
    minter = signers[0];
    burner = signers[1];
    recipient = signers[2];
    finalTarget = signers[3];
    stTara = await deploystTara(minter);
    apyOracle = await deployApyOracle(minter.address, burner.address);
    laraFactory = await deployLaraFactory(
      minter,
      await stTara.getAddress(),
      burner.address,
      await apyOracle.getAddress(),
      ethers.Wallet.createRandom().address
    );
    // simulate Lara addres as minter
    await stTara.connect(minter).setLaraFactory(minter.address);
    expect(await stTara.laraFactory()).to.equal(minter.address);
  });

  it("should not allow setting Lara address if not called by owner", async () => {
    const [, randomAccount, lara] = await ethers.getSigners();
    await expect(
      stTara.connect(randomAccount).setLaraFactory(lara.address)
    ).to.be.revertedWithCustomError(stTara, "OwnableUnauthorizedAccount");
  });

  it("should allow setting Lara address if called by owner", async () => {
    await stTara.connect(minter).setLaraFactory(minter.address);
    expect(await stTara.laraFactory()).to.equal(minter.address);
  });

  it("should not allow setting Lara address if not called by owner", async () => {
    const [, , lara] = await ethers.getSigners();
    await expect(stTara.setLaraFactory(lara.address)).to.not.be.reverted;
    expect(await stTara.laraFactory()).to.equal(lara.address);
    stTara.connect(lara).setLaraFactory(minter);
  });

  it("should not allow the transfer of stTARA tokens if the allowance is not set", async () => {
    const amount = ethers.parseEther("1000");

    const target = ethers.hexlify(ethers.randomBytes(20));

    await expect(
      stTara.connect(minter).transferFrom(recipient.address, target, amount)
    ).to.be.revertedWith("stTARA: transfer amount exceeds balance");
  });
});
