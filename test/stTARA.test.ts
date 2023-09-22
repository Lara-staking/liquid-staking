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

  beforeEach(async () => {
    stTara = await deploystTara();

    initialMinDepositAmount = ethers.utils.parseEther('1000');
    const signers = await ethers.getSigners();
    minter = signers[0];
    burner = signers[1];
    recipient = signers[2];
    finalTarget = signers[3];
  });

  it('should not allow setting minDepositAmount if not called by owner', async() => {
    const [, randomAccount] = await ethers.getSigners();
    await expect(stTara.connect(randomAccount).setMinDepositAmount(3)).to.be.revertedWith('Ownable: caller is not the owner');
  });

  it('should allow setting minDepositAmount if called by owner', async() => {
    const newMinDepositAmount = ethers.utils.parseEther('1500');
    await expect(stTara.setMinDepositAmount(newMinDepositAmount)).to.not.be.reverted;
    expect(await stTara.minDepositAmount()).to.equal(newMinDepositAmount);
  });

  it('should not allow setting Lara address if not called by owner', async() => {
    const [, randomAccount, lara] = await ethers.getSigners();
    await expect(stTara.connect(randomAccount).setLaraAddress(lara.address)).to.be.revertedWith('Ownable: caller is not the owner');
  });

  it('should not allow setting Lara address if not called by owner', async() => {
    const [,, lara] = await ethers.getSigners();
    await expect(stTara.setLaraAddress(lara.address)).to.not.be.reverted;
    expect(await stTara.lara()).to.equal(lara.address);
  });

  it("should not mint stTARA tokens when the minDepositAmount is not met", async () => {
    const amount = ethers.utils.parseEther("999");
    await expect(
      stTara.connect(minter).mint(minter.address, amount, { value: amount })
    ).to.be.revertedWithCustomError(stTara, ErrorsNames.DepositAmountTooLow).withArgs(amount, initialMinDepositAmount);
  });

  it("should mint stTARA tokens when the minDepositAmount is met", async () => {
    const amount = ethers.utils.parseEther("1000");
    expect(
      await stTara.connect(minter).mint(minter.address, amount, { value: amount })
    ).to.emit(stTara, "Minted")
      .withArgs(minter.address, amount)
      .changeTokenBalance(stTara, minter.address, amount)
      .changeEtherBalance(minter.address, amount.mul(-1));
  });

  it("should backswap stTARA tokens for TARA tokens", async () => {
    const amount = ethers.utils.parseEther("1000");
    await stTara.connect(burner).mint(burner.address, amount, { value: amount });
    expect(
      await stTara.connect(burner).burn(burner.address, amount)
    ).to.emit(stTara, "Burned").withArgs(burner.address, amount)
    .to.changeTokenBalance(stTara, burner, amount.mul(-1))
    .to.changeEtherBalance(burner, amount);
  });

  it("should allow the transfer of stTARA tokens", async () => {
    const amount = ethers.utils.parseEther("1000");
    await stTara.connect(burner).mint(burner.address, amount, { value: amount });

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

    await stTara.connect(recipient).mint(recipient.address, amount, {value: amount});

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

  it("should not allow recipient to backswap stTARA tokens for TARA tokens", async () => {
    const amount = ethers.utils.parseEther("1000");

    await expect(stTara.connect(recipient).burn(recipient.address, amount)).to.be.revertedWithCustomError(stTara, ErrorsNames.InsufficientBalanceForBurn).withArgs(amount, 0);
  });

  it("should allow finalTarget to backswap stTARA tokens for TARA tokens", async () => {
    const amount = ethers.utils.parseEther("1000");

    await stTara.connect(recipient).mint(recipient.address, amount, {value: amount});
    await stTara
      .connect(recipient)
      .approve(minter.address, amount);

    await stTara
      .connect(minter)
      .transferFrom(recipient.address, finalTarget.address, amount);

    const balance = await stTara.balanceOf(finalTarget.address);
    expect(balance).to.equal(amount);

    await expect(stTara.connect(finalTarget).burn(finalTarget.address, amount))
      .to.emit(stTara, "Burned")
      .withArgs(finalTarget.address, amount)
      .changeTokenBalance(stTara, finalTarget.address, amount.mul(-1))
      .changeEtherBalance(finalTarget.address, amount);
  });
});
