import { ethers } from "hardhat";
import { ContractsNames } from "../../util/ContractsNames";
import { ApyOracle } from "../../typechain";
import { BigNumber } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

export async function deployApyOracle(dataFeedAddress: string) {
    const ApyOracle = await ethers.getContractFactory(ContractsNames.apyOracle);
    const apyOracle = await ApyOracle.deploy(dataFeedAddress);

    return await apyOracle.deployed();
}

export async function deployNodeContinuityOracle(dataFeedAddress: string) {
    const NodeOracleFactory = await ethers.getContractFactory(ContractsNames.nodeContinuityOracle);
    const nodeOracleProm = await NodeOracleFactory.deploy(
        dataFeedAddress
      );

    return await nodeOracleProm.deployed();
}

export async function deploystTara() {
    const StTara = await ethers.getContractFactory(ContractsNames.stTara);
    const stTara = await StTara.deploy();

    return stTara.deployed();
}

export async function setupApyOracle(apyOracle: ApyOracle, dataFeed: SignerWithAddress) {
    const [,v1, v2, v3] = await ethers.getSigners();
    await apyOracle.connect(dataFeed).updateNodeCount(BigNumber.from(3));
    await apyOracle.connect(dataFeed).updateNodeData(v1.address, {
        account: v1.address,
        rank: 1,
        apy: 5000,
        fromBlock: await ethers.provider.getBlockNumber(),
        toBlock: await ethers.provider.getBlockNumber() + 1000,
        pbftCount: 1000
    })
    await apyOracle.connect(dataFeed).updateNodeData(v2.address, {
        account: v2.address,
        rank: 2,
        apy: 3000,
        fromBlock: await ethers.provider.getBlockNumber(),
        toBlock: await ethers.provider.getBlockNumber() + 1000,
        pbftCount: 1000
    })
    await apyOracle.connect(dataFeed).updateNodeData(v3.address, {
        account: v3.address,
        rank: 3,
        apy: 2000,
        fromBlock: await ethers.provider.getBlockNumber(),
        toBlock: await ethers.provider.getBlockNumber() + 1000,
        pbftCount: 1000
    })
}

export async function deployMockDpos() {
    const [,v1, v2, v3] = await ethers.getSigners();
    const MockDpos = await ethers.getContractFactory(ContractsNames.mockDpos);
    const mockDpos = await MockDpos.deploy([v1.address, v2.address, v3.address], {value: ethers.utils.parseEther('80000000')});


    return await mockDpos.deployed();
}

export async function deployLara(stTaraAddress: string, mockDposAddress: string, apyOracleAddress: string, continuityOracleAddress: string) {
    const Lara = await ethers.getContractFactory(ContractsNames.lara);
    const lara = await Lara.deploy(stTaraAddress, mockDposAddress, apyOracleAddress, continuityOracleAddress);

    return lara.deployed();
}