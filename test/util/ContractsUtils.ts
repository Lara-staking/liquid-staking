import { ethers } from "hardhat";
import { ContractsNames } from "../../util/ContractsNames";

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

export async function deployMockDpos() {
    const [,v0, v1, v2, v3] = await ethers.getSigners();
    const MockDpos = await ethers.getContractFactory(ContractsNames.mockDpos);
    const mockDpos = await MockDpos.deploy([v0.address, v1.address, v2.address, v3.address]);

    return await mockDpos.deployed();
}

export async function deployLara(stTaraAddress: string, mockDposAddress: string, apyOracleAddress: string, continuityOracleAddress: string) {
    const Lara = await ethers.getContractFactory(ContractsNames.lara);
    const lara = await Lara.deploy(stTaraAddress, mockDposAddress, apyOracleAddress, continuityOracleAddress);

    return lara.deployed();
}