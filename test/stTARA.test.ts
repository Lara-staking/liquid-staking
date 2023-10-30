import { ethers } from "hardhat";
import { expect } from "chai";
import { toBigInt } from "ethers";
import { ErrorsNames } from "./util/ErrorsNames";
import { deploystTara } from "./util/ContractsUtils";
import { ContractNames } from "../util/ContractNames";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { StTARA } from "../typechain";

describe(ContractNames.stTara, () => {
  let stTara: StTARA;
  let initialMinDepositAmount: bigint;
  let minter: SignerWithAddress;
  let burner: SignerWithAddress;
  let recipient: SignerWithAddress;
  let finalTarget: SignerWithAddress;

  beforeEach(async () => {
    stTara = await deploystTara();

    initialMinDepositAmount = ethers.parseEther("1000");
    const signers = await ethers.getSigners();
    minter = signers[0];
    burner = signers[1];
    recipient = signers[2];
    finalTarget = signers[3];
  });

  it("should not allow setting minDepositAmount if not called by owner", async () => {
    const [, randomAccount] = await ethers.getSigners();
    await expect(
      stTara.connect(randomAccount).setMinDepositAmount(3)
    ).to.be.revertedWith("Ownable: caller is not the owner");
  });

  it("should allow setting minDepositAmount if called by owner", async () => {
    const newMinDepositAmount = ethers.parseEther("1500");
    await expect(stTara.setMinDepositAmount(newMinDepositAmount)).to.not.be
      .reverted;
    expect(await stTara.minDepositAmount()).to.equal(newMinDepositAmount);
  });

  it("should not allow setting Lara address if not called by owner", async () => {
    const [, randomAccount, lara] = await ethers.getSigners();
    await expect(
      stTara.connect(randomAccount).setLaraAddress(lara.address)
    ).to.be.revertedWith("Ownable: caller is not the owner");
  });

  it("should not allow setting Lara address if not called by owner", async () => {
    const [, , lara] = await ethers.getSigners();
    await expect(stTara.setLaraAddress(lara.address)).to.not.be.reverted;
    expect(await stTara.lara()).to.equal(lara.address);
  });

  it("should not mint stTARA tokens when the minDepositAmount is not met", async () => {
    const amount = ethers.parseEther("999");
    await expect(
      stTara.connect(minter).mint(minter.address, amount, { value: amount })
    )
      .to.be.revertedWithCustomError(stTara, ErrorsNames.DepositAmountTooLow)
      .withArgs(amount, initialMinDepositAmount);
  });

  it("should mint stTARA tokens when the minDepositAmount is met", async () => {
    const amount = ethers.parseEther("1000");
    const mintTx = stTara
      .connect(minter)
      .mint(minter.address, amount, { value: amount });
    await expect(mintTx)
      .to.emit(stTara, "Minted")
      .withArgs(minter.address, amount);
    await expect(mintTx).to.changeTokenBalance(stTara, minter.address, amount);
    await expect(mintTx).to.changeEtherBalance(
      minter.address,
      amount * toBigInt(-1)
    );
  });

  it("should backswap stTARA tokens for TARA tokens", async () => {
    const amount = ethers.parseEther("1000");
    const mintTx = stTara
      .connect(burner)
      .mint(burner.address, amount, { value: amount });
    await expect(mintTx)
      .to.emit(stTara, "Minted")
      .withArgs(burner.address, amount);
    const burnTx = stTara.connect(burner).burn(burner.address, amount);
    await expect(burnTx)
      .to.emit(stTara, "Burned")
      .withArgs(burner.address, amount);
    await expect(burnTx).to.changeTokenBalance(
      stTara,
      burner,
      amount * toBigInt(-1)
    );
    await expect(burnTx).to.changeEtherBalance(burner, amount);
  });

  it("should allow the transfer of stTARA tokens", async () => {
    const amount = ethers.parseEther("1000");
    await stTara
      .connect(burner)
      .mint(burner.address, amount, { value: amount });

    await stTara.connect(burner).transfer(recipient.address, amount);

    const recipientBalanceAfter = await stTara.balanceOf(recipient.address);

    const burnerBalanceAfter = await stTara.balanceOf(burner.address);
    expect(burnerBalanceAfter).to.equal(0);
    expect(recipientBalanceAfter).to.equal(amount);
  });

  it("should not allow the transfer of stTARA tokens if the allowance is not set", async () => {
    const amount = ethers.parseEther("1000");

    const target = ethers.hexlify(ethers.randomBytes(20));

    await expect(
      stTara.connect(minter).transferFrom(recipient.address, target, amount)
    ).to.be.revertedWith("ERC20: insufficient allowance");
  });

  it("should allow the transfer of stTARA tokens if the allowance is set", async () => {
    const amount = ethers.parseEther("1000");

    await stTara
      .connect(recipient)
      .mint(recipient.address, amount, { value: amount });

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

    await expect(stTara.connect(recipient).burn(recipient.address, amount))
      .to.be.revertedWithCustomError(
        stTara,
        ErrorsNames.InsufficientUserBalanceForBurn
      )
      .withArgs(amount, 0, 0);
  });

  it("should allow finalTarget to backswap stTARA tokens for TARA tokens", async () => {
    const amount = ethers.parseEther("1000");

    await stTara
      .connect(recipient)
      .mint(recipient.address, amount, { value: amount });
    await stTara.connect(recipient).approve(minter.address, amount);

    await stTara
      .connect(minter)
      .transferFrom(recipient.address, finalTarget.address, amount);

    const balance = await stTara.balanceOf(finalTarget.address);
    expect(balance).to.equal(amount);

    const burnTx = stTara
      .connect(finalTarget)
      .burn(finalTarget.address, amount);

    await expect(burnTx)
      .to.emit(stTara, "Burned")
      .withArgs(finalTarget.address, amount);
    await expect(burnTx).to.changeTokenBalance(
      stTara,
      finalTarget.address,
      amount * toBigInt(-1)
    );
    await expect(burnTx).to.changeEtherBalance(finalTarget.address, amount);
  });
});
