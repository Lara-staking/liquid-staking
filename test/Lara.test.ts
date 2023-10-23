import { ethers } from "hardhat";
import { time } from "@nomicfoundation/hardhat-network-helpers";
import { ContractsNames } from "../util/ContractsNames";
import { ApyOracle, Lara, MockDpos, NodeContinuityOracle, StTARA } from "../typechain";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { deployApyOracle, deployLara, deployMockDpos, deployNodeContinuityOracle, deploystTara, setupApyOracle } from "./util/ContractsUtils";
import { BigNumber, Contract } from "ethers";
import { expect } from "chai";
import { ErrorsNames } from "./util/ErrorsNames";

describe(ContractsNames.lara, function() {
    let mockDpos: MockDpos;
    let nodeContinuityOracle: NodeContinuityOracle;
    let apyOracle: ApyOracle;
    let stTara: Contract;
    let lara: Lara;
    let dataFeed: SignerWithAddress;
    let v1: SignerWithAddress;
    let v2: SignerWithAddress;
    let v3: SignerWithAddress;
    let v1InitialTotalStake: BigNumber;
    let v2InitialTotalStake: BigNumber;
    let v3InitialTotalStake: BigNumber;
    const maxValidatorStakeCapacity = ethers.utils.parseEther("80000000");
    const initialMinStake = ethers.utils.parseEther("1000");
    const initialEpochDuration = 7*24*60*60;

    beforeEach(async() => {
        dataFeed = (await ethers.getSigners())[1];
        [,v1, v2, v3] = await ethers.getSigners();
        mockDpos = await deployMockDpos();
        nodeContinuityOracle = await deployNodeContinuityOracle(dataFeed.address);
        apyOracle = await deployApyOracle(dataFeed.address);
        await setupApyOracle(apyOracle, dataFeed);
        stTara = await deploystTara();
        lara = await deployLara(stTara.address, mockDpos.address, apyOracle.address, nodeContinuityOracle.address);
        await stTara.setLaraAddress(lara.address);
        v1InitialTotalStake = (await mockDpos.getValidator(v1.address)).total_stake;
        v2InitialTotalStake = (await mockDpos.getValidator(v2.address)).total_stake;
        v3InitialTotalStake = (await mockDpos.getValidator(v3.address)).total_stake;
    });

    describe('Getters/Setters', function() {
        it('should correctly set the initial state variables', async() => {
            expect(await lara.apyOracle()).to.equal(apyOracle.address);
            expect(await lara.dposContract()).to.equal(mockDpos.address);
            expect(await lara.continuityOracle()).to.equal(nodeContinuityOracle.address);
            expect(await lara.stTaraToken()).to.equal(stTara.address);
            expect(await lara.epochDuration()).to.equal(initialEpochDuration);
            expect(await lara.getEpoch()).to.equal(1);
        });

        it('should correctly compute the epoch number', async() => {
            await time.increase(initialEpochDuration * 4);
            expect(await lara.getEpoch()).to.equal(5);
        });

        it('should not allow setting epoch duration stake capacity if not called by owner', async() => {
            const newEpochDuration = 14*24*60*60;            
            await expect(lara.setEpochDuration(newEpochDuration))
            .to.not.be.reverted;
            expect(await lara.epochDuration()).to.equal(newEpochDuration);
        });

        it('should not allow setting max valdiator stake capacity if not called by owner', async() => {
            const [, randomAccount] = await ethers.getSigners();
            const initialMaxValidatorStakeCap = ethers.utils.parseEther("80000000");
            expect(await lara.maxValidatorStakeCapacity()).to.equal(initialMaxValidatorStakeCap);
            await expect(lara.connect(randomAccount).setMaxValdiatorStakeCapacity(initialMaxValidatorStakeCap.add(10)))
            .to.be.revertedWith('Ownable: caller is not the owner');
        });

        it('should allow setting max valdiator stake capacity if called by the owner', async() => {
            const initialMaxValidatorStakeCap = ethers.utils.parseEther("80000000");
            expect(await lara.maxValidatorStakeCapacity()).to.equal(initialMaxValidatorStakeCap);
            await expect(lara.setMaxValdiatorStakeCapacity(initialMaxValidatorStakeCap.add(10)))
            .to.not.be.reverted;
            expect(await lara.maxValidatorStakeCapacity()).to.equal(initialMaxValidatorStakeCap.add(10));
        });

        it('should not allow setting min stake amount if not called by owner', async() => {
            const [, randomAccount] = await ethers.getSigners();
            expect(await lara.minStakeAmount()).to.equal(initialMinStake);
            await expect(lara.connect(randomAccount).setMinStakeAmount(initialMinStake.add(10)))
            .to.be.revertedWith('Ownable: caller is not the owner');
        });

        it('should allow setting min stake amount if called by owner', async() => {
            const initialMinStake = ethers.utils.parseEther("1000");
            expect(await lara.minStakeAmount()).to.equal(initialMinStake);
            await expect(lara.setMinStakeAmount(initialMinStake.add(10)))
            .to.not.be.reverted;
            expect(await lara.minStakeAmount()).to.equal(initialMinStake.add(10));
        });
    });

    describe('Staking', function() {
        it('should not allow staking if the amount is lower than min', async() => {
            const amountToStake = ethers.utils.parseEther('100');
            await expect(lara.stake(amountToStake)).to.be.revertedWithCustomError(lara, ErrorsNames.StakeAmountTooLow)
            .withArgs(amountToStake, initialMinStake);
        });

        it('should not allow staking if the value sent is lower than the amount', async() => {
            const amountToStake = ethers.utils.parseEther('1001');
            await expect(lara.stake(amountToStake, {value: ethers.utils.parseEther('2')})).to.be.revertedWithCustomError(lara, ErrorsNames.StakeValueTooLow)
            .withArgs(ethers.utils.parseEther('2'), amountToStake);
        });

        it('should allow staking if values are correct for one validator', async() => {
            const [,,,,staker] = await ethers.getSigners();
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

            // Test that the user cannot burn the protocol balance
            const mintAmount = ethers.utils.parseEther('1010');
            await stTara.connect(staker).mint(staker.address, mintAmount, {value: mintAmount});
            await expect(
                stTara.connect(staker).burn(staker.address, amountToStake.add(mintAmount))
            ).to.be.revertedWithCustomError(stTara, ErrorsNames.InsufficientUserBalanceForBurn)
            .withArgs(amountToStake.add(mintAmount), amountToStake.add(mintAmount), amountToStake);

            // Test that the user can burn amount outside of protocol balance
            expect(await stTara.connect(staker).burn(staker.address, mintAmount))
            .to.emit(stTara, 'Burned')
            .withArgs(staker.address, mintAmount)
            .to.changeEtherBalance(staker.address, mintAmount)
            .to.changeTokenBalance(stTara, staker.address, mintAmount.mul(-1));

            // Set an account as lara
            // Test that lara cannot burn a value greater than protocol balance
            const [, , ,randomLara] = await ethers.getSigners();
            await stTara.setLaraAddress(randomLara.address);
            await expect(
                stTara.connect(randomLara).burn(staker.address, amountToStake.add(mintAmount))
            ).to.be.revertedWithCustomError(stTara, ErrorsNames.InsufficientProtocolBalanceForBurn)
            .withArgs(amountToStake.add(mintAmount), amountToStake);

            // Test that the user can burn from the protocol balance
            const amountToBurn = amountToStake.sub(100);
            expect(await stTara.connect(randomLara).burn(staker.address, amountToBurn))
            .to.emit(stTara, 'Burned')
            .withArgs(staker.address, amountToBurn)
            .to.changeTokenBalance(stTara, staker.address, amountToBurn.mul(-1));

            expect(await stTara.protocolBalances(staker.address)).to.equal(amountToStake.sub(amountToBurn));
        });

        it('should allow staking if values are correct for multiple validators', async() => {
            const [,,,,staker] = await ethers.getSigners();
            const amountToStake = ethers.utils.parseEther('60000000');
            const stakedAmountBefore = await lara.stakedAmounts(staker.address);
            const protocolBalanceBefore = await stTara.protocolBalances(staker.address);
            const v1AmountToFill = maxValidatorStakeCapacity.sub(v1InitialTotalStake);
            const v2AmountToFill = amountToStake.sub(v1AmountToFill);

            await expect(lara.connect(staker).stake(amountToStake, {value: amountToStake}))
            .to.emit(lara, 'Staked')
            .withArgs(staker.address, amountToStake)
            .and.to.emit(mockDpos, 'Delegated')
            .withArgs(lara.address, v1.address, v1AmountToFill)
            .and.to.emit(mockDpos, 'Delegated')
            .withArgs(lara.address, v2.address, v2AmountToFill)
            .and.to.changeTokenBalance(stTara, staker, amountToStake)
            .and.to.changeEtherBalance(staker, amountToStake.mul(-1));
            
            const stakedAmountAfter = await lara.stakedAmounts(staker.address);
            const protocolBalanceAfter = await stTara.protocolBalances(staker.address);
            expect(stakedAmountAfter).to.equal(stakedAmountBefore.add(amountToStake));
            expect(protocolBalanceAfter).to.equal(protocolBalanceBefore.add(amountToStake));

            expect((await mockDpos.getValidator(v1.address)).total_stake).to.equal(maxValidatorStakeCapacity);
            expect((await mockDpos.getValidator(v2.address)).total_stake).to.equal(v2InitialTotalStake.add(v2AmountToFill));
            
        });

        it('should allow staking with amount greater than total capacity', async() => {
            const [,,,,staker] = await ethers.getSigners();
            const surplusAmount = ethers.utils.parseEther('1000');
            const amountToStake = maxValidatorStakeCapacity.mul(3).sub(v1InitialTotalStake).sub(v2InitialTotalStake).sub(v3InitialTotalStake).add(surplusAmount);
            const stakedAmountBefore = await lara.stakedAmounts(staker.address);
            const protocolBalanceBefore = await stTara.protocolBalances(staker.address);
            const v1AmountToFill = maxValidatorStakeCapacity.sub(v1InitialTotalStake);
            const v2AmountToFill = maxValidatorStakeCapacity.sub(amountToStake.sub(v1AmountToFill));
            const v3AmountToFill = maxValidatorStakeCapacity.sub(amountToStake.sub(v1AmountToFill).sub(v2AmountToFill));

            await expect(lara.connect(staker).stake(amountToStake, {value: amountToStake}))
            .to.emit(lara, 'Staked')
            .withArgs(staker.address, amountToStake)
            .and.to.emit(mockDpos, 'Delegated')
            .withArgs(lara.address, v1.address, v1AmountToFill)
            .and.to.emit(mockDpos, 'Delegated')
            .withArgs(lara.address, v2.address, v2AmountToFill)
            .and.to.emit(mockDpos, 'Delegated')
            .withArgs(lara.address, v3.address, v3AmountToFill)
            .and.to.changeTokenBalance(stTara, staker, amountToStake.sub(surplusAmount))
            .and.to.changeEtherBalance(staker, amountToStake.sub(surplusAmount).mul(-1));
            
            const stakedAmountAfter = await lara.stakedAmounts(staker.address);
            const protocolBalanceAfter = await stTara.protocolBalances(staker.address);
            expect(stakedAmountAfter).to.equal(stakedAmountBefore.add(amountToStake.sub(surplusAmount)));
            expect(protocolBalanceAfter).to.equal(protocolBalanceBefore.add(amountToStake.sub(surplusAmount)));

            expect((await mockDpos.getValidator(v1.address)).total_stake).to.equal(maxValidatorStakeCapacity);
            expect((await mockDpos.getValidator(v2.address)).total_stake).to.equal(maxValidatorStakeCapacity);
            expect((await mockDpos.getValidator(v3.address)).total_stake).to.equal(maxValidatorStakeCapacity);
        });
    });
});