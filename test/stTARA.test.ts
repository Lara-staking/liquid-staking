import { ethers } from "hardhat";
import { expect } from "chai";
import { toBigInt } from "ethers";
import { ErrorsNames } from "./util/ErrorsNames";
import { deploystTara } from "./util/ContractsUtils";
import { ContractNames } from "../util/ContractNames";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { StakedNativeAsset } from "../typechain";

describe(ContractNames.stTara, () => {
  let stTara: StakedNativeAsset;
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
    stTara = await deploystTara();
    // simulate Lara addres as minter
    await stTara.connect(minter).setLaraAddress(minter.address);
    expect(await stTara.lara()).to.equal(minter.address);
  });

  it("should not allow setting Lara address if not called by owner", async () => {
    const [, randomAccount, lara] = await ethers.getSigners();
    await expect(
      stTara.connect(randomAccount).setLaraAddress(lara.address)
    ).to.be.revertedWithCustomError(stTara, "OwnableUnauthorizedAccount");
  });

  it("should not allow setting Lara address if not called by owner", async () => {
    const [, , lara] = await ethers.getSigners();
    await expect(stTara.setLaraAddress(lara.address)).to.not.be.reverted;
    expect(await stTara.lara()).to.equal(lara.address);
    stTara.connect(lara).setLaraAddress(minter);
  });

  it("should mint stTARA tokens when the minDepositAmount is met and owner called", async () => {
    const amount = ethers.parseEther("1000");
    const mintTx = stTara.connect(minter).mint(minter.address, amount);
    await expect(mintTx)
      .to.emit(stTara, "Transfer")
      .withArgs(ethers.ZeroAddress, minter.address, amount);
    await expect(mintTx).to.changeTokenBalance(stTara, minter.address, amount);
    await expect(mintTx).not.to.changeEtherBalance;
  });

  it("should backswap stTARA tokens for TARA tokens", async () => {
    const amount = ethers.parseEther("1000");
    const mintTx = stTara.connect(minter).mint(burner.address, amount);
    await expect(mintTx)
      .to.emit(stTara, "Transfer")
      .withArgs(ethers.ZeroAddress, burner.address, amount);
    stTara.connect(minter).transfer(burner.address, amount);
    const burnTx = stTara.connect(minter).burn(burner.address, amount);
    await expect(burnTx)
      .to.emit(stTara, "Transfer")
      .withArgs(burner.address, ethers.ZeroAddress, amount);
    await expect(burnTx).to.changeTokenBalance(
      stTara,
      burner,
      amount * toBigInt(-1)
    );
  });

  it("should allow the transfer of stTARA tokens for everybody", async () => {
    const amount = ethers.parseEther("1000");
    await stTara.connect(minter).mint(burner.address, amount);

    await stTara.connect(burner).transfer(recipient.address, amount);

    const recipientBalanceAfter = await stTara.balanceOf(recipient.address);

    const minterBalanceAfter = await stTara.balanceOf(burner.address);
    expect(minterBalanceAfter).to.equal(0);
    expect(recipientBalanceAfter).to.equal(amount);
    await stTara.connect(recipient).transfer(burner.address, amount);
    expect(await stTara.balanceOf(recipient.address)).to.equal(0);
    expect(await stTara.balanceOf(burner.address)).to.equal(amount);
  });

  it("should not allow the transfer of stTARA tokens if the allowance is not set", async () => {
    const amount = ethers.parseEther("1000");

    const target = ethers.hexlify(ethers.randomBytes(20));

    await expect(
      stTara.connect(minter).transferFrom(recipient.address, target, amount)
    ).to.be.revertedWithCustomError(stTara, "ERC20InsufficientAllowance");
  });

  it("should allow the transfer of stTARA tokens if the allowance is set", async () => {
    const amount = ethers.parseEther("1000");

    await stTara.connect(minter).mint(recipient.address, amount);

    const balance = await stTara.balanceOf(recipient.address);
    expect(balance).to.equal(amount);

    await stTara.connect(recipient).approve(minter.address, amount);

    await stTara
      .connect(minter)
      .transferFrom(recipient.address, finalTarget.address, amount);

    const targetBalanceAfter = await stTara.balanceOf(finalTarget.address);
    expect(targetBalanceAfter).to.equal(amount);

    const recipientBalanceAfter = await stTara.balanceOf(recipient.address);
    expect(recipientBalanceAfter).to.equal(0);
  });

  it("should not allow recipient to backswap stTARA tokens for TARA tokens", async () => {
    const amount = ethers.parseEther("1000");

    await expect(
      stTara.connect(minter).burn(recipient.address, amount)
    ).to.be.revertedWithCustomError(stTara, "ERC20InsufficientBalance");
  });
});
