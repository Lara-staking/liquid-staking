import { ethers } from "hardhat";
import { ContractsNames } from "../util/ContractsNames";
import { ApyOracle, Lara, MockDpos, NodeContinuityOracle, StTARA } from "../typechain";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { deployApyOracle, deployLara, deployMockDpos, deployNodeContinuityOracle, deploystTara, setupApyOracle } from "./util/ContractsUtils";
import { Contract } from "ethers";
import { expect } from "chai";
import { ErrorsNames } from "./util/ErrorsNames";

describe(ContractsNames.lara, function() {
    let mockDpos: MockDpos;
    let nodeContinuityOracle: NodeContinuityOracle;
    let apyOracle: ApyOracle;
    let stTara: Contract;
    let lara: Lara;
    let dataFeed: SignerWithAddress;
    const initialMinStake = ethers.utils.parseEther("1000");

    beforeEach(async() => {
        dataFeed = (await ethers.getSigners())[1];
        mockDpos = await deployMockDpos();
        nodeContinuityOracle = await deployNodeContinuityOracle(dataFeed.address);
        apyOracle = await deployApyOracle(dataFeed.address);
        await setupApyOracle(apyOracle, dataFeed);
        stTara = await deploystTara();
        lara = await deployLara(stTara.address, mockDpos.address, apyOracle.address, nodeContinuityOracle.address);
        await stTara.setLaraAddress(lara.address);
    });

    describe('Getters/Setters', function() {
        it('Should not allow setting max valdiator stake capacity if not called by owner', async() => {
            const [, randomAccount] = await ethers.getSigners();
            const initialMaxValidatorStakeCap = ethers.utils.parseEther("80000000");
            expect(await lara.maxValidatorStakeCapacity()).to.equal(initialMaxValidatorStakeCap);
            await expect(lara.connect(randomAccount).setMaxValdiatorStakeCapacity(initialMaxValidatorStakeCap.add(10)))
            .to.be.revertedWith('Ownable: caller is not the owner');
        });

        it('Should allow setting max valdiator stake capacity if called by the owner', async() => {
            const initialMaxValidatorStakeCap = ethers.utils.parseEther("80000000");
            expect(await lara.maxValidatorStakeCapacity()).to.equal(initialMaxValidatorStakeCap);
            await expect(lara.setMaxValdiatorStakeCapacity(initialMaxValidatorStakeCap.add(10)))
            .to.not.be.reverted;
            expect(await lara.maxValidatorStakeCapacity()).to.equal(initialMaxValidatorStakeCap.add(10));
        });

        it('Should not allow setting min stake amount if not called by owner', async() => {
            const [, randomAccount] = await ethers.getSigners();
            expect(await lara.minStakeAmount()).to.equal(initialMinStake);
            await expect(lara.connect(randomAccount).setMinStakeAmount(initialMinStake.add(10)))
            .to.be.revertedWith('Ownable: caller is not the owner');
        });

        it('Should allow setting min stake amount if called by owner', async() => {
            const initialMinStake = ethers.utils.parseEther("1000");
            expect(await lara.minStakeAmount()).to.equal(initialMinStake);
            await expect(lara.setMinStakeAmount(initialMinStake.add(10)))
            .to.not.be.reverted;
            expect(await lara.minStakeAmount()).to.equal(initialMinStake.add(10));
        });
    });

    describe('Staking', function() {
        it('Should not allow staking if the amount is lower than min', async() => {
            const amountToStake = ethers.utils.parseEther('100');
            await expect(lara.stake(amountToStake)).to.be.revertedWithCustomError(lara, ErrorsNames.StakeAmountTooLow)
            .withArgs(amountToStake, initialMinStake);
        });

        it('Should not allow staking if the value sent is lower than the amount', async() => {
            const amountToStake = ethers.utils.parseEther('1001');
            await expect(lara.stake(amountToStake, {value: ethers.utils.parseEther('2')})).to.be.revertedWithCustomError(lara, ErrorsNames.StakeValueTooLow)
            .withArgs(ethers.utils.parseEther('2'), amountToStake);
        });

        it('Should allow staking if values are correct for one validator', async() => {
            const [,v1,,,staker] = await ethers.getSigners();
            const amountToStake = ethers.utils.parseEther('1001');
            const stakedAmountBefore = await lara.stakedAmounts(staker.address);
            const protocolBalanceBefore = await stTara.protocolBalances(staker.address);
            await expect(lara.connect(staker).stake(amountToStake, {value: amountToStake}))
            .to.emit(lara, 'Staked')
            .withArgs(staker.address, amountToStake)
            .to.emit(mockDpos, 'Delegated')
            .withArgs(lara.address, v1.address, amountToStake)
            .to.changeTokenBalance(stTara, staker, amountToStake);
            
            const stakedAmountAfter = await lara.stakedAmounts(staker.address);
            const protocolBalanceAfter = await stTara.protocolBalances(staker.address);
            expect(stakedAmountAfter).to.equal(stakedAmountBefore.add(amountToStake));
            expect(protocolBalanceAfter).to.equal(protocolBalanceBefore.add(amountToStake));

            //Test that the user cannot burn the protocol balance
            const mintAmount = ethers.utils.parseEther('1010');
            await stTara.connect(staker).mint(staker.address, mintAmount, {value: mintAmount});
            await expect(
                stTara.connect(staker).burn(staker.address, amountToStake.add(mintAmount))
            ).to.be.revertedWithCustomError(stTara, ErrorsNames.InsufficientBalanceForBurn)
            .withArgs(amountToStake.add(mintAmount), amountToStake.add(mintAmount));
        });
    });
});