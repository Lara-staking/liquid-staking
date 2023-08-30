import { ethers, network } from "hardhat";
import { expect } from "chai";
import { Contract, Signer } from "ethers";

describe("stTARA", () => {
  let contract: Contract;
  let minter: Signer;
  let burner: Signer;
  let recipient: Signer;
  let finalTarget: Signer;

  before(async () => {
    const contractF = await ethers.getContractFactory("stTARA");
    contract = await contractF.deploy();

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
      "0x0",
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

  it("should not mint stTARA tokens when the minDelegateAmount is not met", async () => {
    const amount = ethers.utils.parseEther("999");
    await expect(
      contract.connect(minter).mint({ value: amount })
    ).to.be.revertedWith("Needs to be at least equal to minDelegateAmount");
  });

  it("should mint stTARA tokens when the minDelegateAmount is met", async () => {
    const amount = ethers.utils.parseEther("1000");
    await contract.connect(minter).mint({ value: amount });
    const minterAddress = await minter.getAddress();
    const balanceAfter = await contract.balanceOf(minterAddress);
    expect(balanceAfter).to.equal(amount);
    expect(balanceAfter)
      .to.emit(contract, "Minted")
      .withArgs(minterAddress, amount);
  });

  it("should backswap stTARA tokens for TARA tokens", async () => {
    const amount = ethers.utils.parseEther("1000");
    await contract.connect(burner).mint({ value: amount });

    await contract.connect(burner).burn(amount);
    const burnerAddress = await burner.getAddress();
    const burnerBalanceAfter = await contract.balanceOf(burnerAddress);
    expect(burnerBalanceAfter).to.equal(0);
    expect(await ethers.provider.getBalance(await burner.getAddress()))
      .to.be.lt(ethers.utils.parseEther("1001"))
      .and.gt(ethers.utils.parseEther("1000"));
  });

  it("should allow the transfer of stTARA tokens", async () => {
    const amount = ethers.utils.parseEther("1000");
    await contract.connect(burner).mint({ value: amount });

    await contract
      .connect(burner)
      .transfer(await recipient.getAddress(), amount);

    const recipientBalanceAfter = await contract.balanceOf(
      await recipient.getAddress()
    );

    const burnerBalanceAfter = await contract.balanceOf(
      await burner.getAddress()
    );
    expect(burnerBalanceAfter).to.equal(0);
    expect(recipientBalanceAfter).to.equal(amount);
  });

  it("should not allow the transfer of stTARA tokens if the allowance is not set", async () => {
    const amount = ethers.utils.parseEther("1000");

    const target = ethers.utils.hexlify(ethers.utils.randomBytes(20));

    const recipientAddress = await recipient.getAddress();
    await expect(
      contract.connect(minter).transferFrom(recipientAddress, target, amount)
    ).to.be.revertedWith("ERC20: insufficient allowance");
  });

  it("should allow the transfer of stTARA tokens if the allowance is set", async () => {
    const amount = ethers.utils.parseEther("1000");

    await network.provider.send("hardhat_setBalance", [
      await recipient.getAddress(),
      ethers.utils.parseEther("5").toHexString(),
    ]);

    const balance = await contract.balanceOf(await recipient.getAddress());
    expect(balance).to.equal(amount);

    await contract
      .connect(recipient)
      .approve(await minter.getAddress(), amount);

    const recipientAddress = await recipient.getAddress();
    const finalTargetAddress = await finalTarget.getAddress();
    await contract
      .connect(minter)
      .transferFrom(recipientAddress, finalTargetAddress, amount);

    const targetBalanceAfter = await contract.balanceOf(finalTargetAddress);
    expect(targetBalanceAfter).to.equal(amount);

    const recipientBalanceAfter = await contract.balanceOf(
      await recipient.getAddress()
    );
    expect(recipientBalanceAfter).to.equal(0);
  });

  it("Should not allow recipient to backswap stTARA tokens for TARA tokens", async () => {
    const amount = ethers.utils.parseEther("1000");

    await expect(contract.connect(recipient).burn(amount)).to.be.revertedWith(
      "Insufficient stTARA balance"
    );
  });

  it("Should allow finalTarget to backswap stTARA tokens for TARA tokens", async () => {
    const amount = ethers.utils.parseEther("1000");

    const finalTargetAddress = await finalTarget.getAddress();
    const balance = await contract.balanceOf(finalTargetAddress);
    expect(balance).to.equal(amount);
    await expect(contract.connect(finalTarget).burn(amount))
      .to.emit(contract, "Burned")
      .withArgs(finalTargetAddress, amount);

    const finalstTaraBalanceAfter = await contract.balanceOf(
      finalTargetAddress
    );
    expect(finalstTaraBalanceAfter).to.equal(0);
    expect(await ethers.provider.getBalance(finalTargetAddress))
      .to.be.lt(ethers.utils.parseEther("1002"))
      .and.gt(ethers.utils.parseEther("1001"));
  });
});
