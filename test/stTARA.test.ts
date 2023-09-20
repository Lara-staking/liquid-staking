import { ethers, network } from "hardhat";
import { expect } from "chai";
import { BigNumber, Contract, Signer } from "ethers";
import { ContractsNames } from "../util/ContractsNames";
import { ErrorsNames } from "./util/ErrorsNames";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { deploystTara } from "./util/ContractsUtils";

describe(ContractsNames.stTara, () => {
  let stTara: Contract;
  let initialMinDepositAmount: BigNumber;
  let minter: SignerWithAddress;
  let burner: SignerWithAddress;
  let recipient: SignerWithAddress;
  let finalTarget: SignerWithAddress;

  before(async () => {
    stTara = await deploystTara();

    initialMinDepositAmount = ethers.utils.parseEther('1000');
    const signers = await ethers.getSigners();
    minter = signers[0];
    burner = signers[1];
    recipient = signers[2];
    finalTarget = signers[3];

    const initialBalanceSigner1 = ethers.utils.parseEther("1001"); // Set the desired initial balance in ether
    const initialBalanceSigner2 = ethers.utils.parseEther("1001"); // Set the desired initial balance in ether

    await network.provider.send("hardhat_setBalance", [
      await minter.getAddress(),
      initialBalanceSigner1.toHexString(),
    ]);

    await network.provider.send("hardhat_setBalance", [
      await burner.getAddress(),
      initialBalanceSigner2.toHexString(),
    ]);

    await network.provider.send("hardhat_setBalance", [
      await recipient.getAddress(),
      ethers.utils.parseEther("2").toHexString(),
    ]);

    await network.provider.send("hardhat_setBalance", [
      await finalTarget.getAddress(),
      ethers.utils.parseEther("2").toHexString(),
    ]);
  });

  it("should have the correct initial balances", async function () {
    expect(
      await ethers.provider.getBalance(await minter.getAddress())
    ).to.equal(ethers.utils.parseEther("1001"));
    expect(
      await ethers.provider.getBalance(await burner.getAddress())
    ).to.equal(ethers.utils.parseEther("1001"));
  });

  it("should not mint stTARA tokens when the minDepositAmount is not met", async () => {
    const amount = ethers.utils.parseEther("999");
    await expect(
      stTara.connect(minter).mint({ value: amount })
    ).to.be.revertedWithCustomError(stTara, ErrorsNames.DepositAmountTooLow).withArgs(amount, initialMinDepositAmount);
  });

  it("should mint stTARA tokens when the minDepositAmount is met", async () => {
    const amount = ethers.utils.parseEther("1000");
    expect(
      await stTara.connect(minter).mint({ value: amount })
    ).to.emit(stTara, "Minted")
      .withArgs(minter.address, amount)
      .changeTokenBalance(stTara, minter.address, amount)
      .changeEtherBalance(minter.address, amount.mul(-1));
  });

  it("should backswap stTARA tokens for TARA tokens", async () => {
    const amount = ethers.utils.parseEther("1000");
    await stTara.connect(burner).mint({ value: amount });
    expect(
      await stTara.connect(burner).burn(amount)
    ).to.emit(stTara, "Burned").withArgs(burner.address, amount)
    .to.changeTokenBalance(stTara, burner, amount.mul(-1))
    .to.changeEtherBalance(burner, amount);
  });

  it("should allow the transfer of stTARA tokens", async () => {
    const amount = ethers.utils.parseEther("1000");
    await stTara.connect(burner).mint({ value: amount });

    await stTara
      .connect(burner)
      .transfer(recipient.address, amount);

    const recipientBalanceAfter = await stTara.balanceOf(
      recipient.address
    );

    const burnerBalanceAfter = await stTara.balanceOf(
      burner.address
    );
    expect(burnerBalanceAfter).to.equal(0);
    expect(recipientBalanceAfter).to.equal(amount);
  });

  it("should not allow the transfer of stTARA tokens if the allowance is not set", async () => {
    const amount = ethers.utils.parseEther("1000");

    const target = ethers.utils.hexlify(ethers.utils.randomBytes(20));

    await expect(
      stTara.connect(minter).transferFrom(recipient.address, target, amount)
    ).to.be.revertedWith("ERC20: insufficient allowance");
  });

  it("should allow the transfer of stTARA tokens if the allowance is set", async () => {
    const amount = ethers.utils.parseEther("1000");

    await network.provider.send("hardhat_setBalance", [
      recipient.address,
      ethers.utils.parseEther("5").toHexString(),
    ]);

    const balance = await stTara.balanceOf(recipient.address);
    expect(balance).to.equal(amount);

    await stTara
      .connect(recipient)
      .approve(minter.address, amount);

    await stTara
      .connect(minter)
      .transferFrom(recipient.address, finalTarget.address, amount);

    const targetBalanceAfter = await stTara.balanceOf(finalTarget.address);
    expect(targetBalanceAfter).to.equal(amount);

    const recipientBalanceAfter = await stTara.balanceOf(
      recipient.address
    );
    expect(recipientBalanceAfter).to.equal(0);
  });

  it("Should not allow recipient to backswap stTARA tokens for TARA tokens", async () => {
    const amount = ethers.utils.parseEther("1000");

    await expect(stTara.connect(recipient).burn(amount)).to.be.revertedWithCustomError(stTara, ErrorsNames.InsufficientBalanceForBurn).withArgs(amount, 0);
  });

  it("Should allow finalTarget to backswap stTARA tokens for TARA tokens", async () => {
    const amount = ethers.utils.parseEther("1000");

    const balance = await stTara.balanceOf(finalTarget.address);
    expect(balance).to.equal(amount);
    await expect(stTara.connect(finalTarget).burn(amount))
      .to.emit(stTara, "Burned")
      .withArgs(finalTarget.address, amount);

    const finalstTaraBalanceAfter = await stTara.balanceOf(
      finalTarget.address
    );
    expect(finalstTaraBalanceAfter).to.equal(0);
    expect(await ethers.provider.getBalance(finalTarget.address))
      .to.be.lt(ethers.utils.parseEther("1002"))
      .and.gt(ethers.utils.parseEther("1001"));
  });
});
