import { ethers } from "hardhat";
import { ContractsNames } from "../util/ContractsNames";
import { ApyOracle, Lara, MockDpos, NodeContinuityOracle, StTARA } from "../typechain";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { deployApyOracle, deployLara, deployMockDpos, deployNodeContinuityOracle, deploystTara } from "./util/ContractsUtils";
import { Contract } from "ethers";
import { expect } from "chai";

describe(ContractsNames.lara, function() {
    let mockDpos: MockDpos;
    let nodeContinuityOracle: NodeContinuityOracle;
    let apyOracle: ApyOracle;
    let stTara: Contract;
    let lara: Lara;
    let dataFeed: SignerWithAddress;

    this.beforeAll(async() => {
        dataFeed = (await ethers.getSigners())[1];
        mockDpos = await deployMockDpos();
        console.log('hmm');
        nodeContinuityOracle = await deployNodeContinuityOracle(dataFeed.address);
        apyOracle = await deployApyOracle(dataFeed.address);
        stTara = await deploystTara();
        lara = await deployLara(stTara.address, mockDpos.address, apyOracle.address, nodeContinuityOracle.address);
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
            const initialMinStake = ethers.utils.parseEther("1000");
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
});