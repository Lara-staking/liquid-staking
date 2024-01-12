import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { ContractNames } from "../../util/ContractNames";
import { ApyOracle } from "../../typechain/contracts";
import { StTARA } from "../../typechain";

export async function deployApyOracle(
  dataFeedAddress: string,
  dposAddress: string
): Promise<ApyOracle> {
  const ApyOracle = await ethers.getContractFactory(ContractNames.apyOracle);
  const apyOracle = await ApyOracle.deploy(dataFeedAddress, dposAddress);

  return await apyOracle.waitForDeployment();
}

export async function deploystTara(owner: SignerWithAddress): Promise<StTARA> {
  const StTara = await ethers.getContractFactory(ContractNames.stTara);
  const stTara = await StTara.connect(owner).deploy();

  return (await stTara.waitForDeployment()) as StTARA;
}

export async function setupApyOracle(
  apyOracle: ApyOracle,
  dataFeed: SignerWithAddress
) {
  const [, v1, v2, v3] = await ethers.getSigners();
  await apyOracle.connect(dataFeed).updateNodeData(v1.address, {
    account: v1.address,
    rank: 1,
    apy: 5000,
    fromBlock: await ethers.provider.getBlockNumber(),
    toBlock: (await ethers.provider.getBlockNumber()) + 1000,
    rating: 100,
  });
  await apyOracle.connect(dataFeed).updateNodeData(v2.address, {
    account: v2.address,
    rank: 2,
    apy: 3000,
    fromBlock: await ethers.provider.getBlockNumber(),
    toBlock: (await ethers.provider.getBlockNumber()) + 1000,
    rating: 97,
  });
  await apyOracle.connect(dataFeed).updateNodeData(v3.address, {
    account: v3.address,
    rank: 3,
    apy: 2000,
    fromBlock: await ethers.provider.getBlockNumber(),
    toBlock: (await ethers.provider.getBlockNumber()) + 1000,
    rating: 93,
  });
}

export async function deployMockDpos() {
  const [, v1, v2, v3] = await ethers.getSigners();
  const MockDpos = await ethers.getContractFactory(ContractNames.mockDpos);
  const mockDpos = await MockDpos.deploy([v1.address, v2.address, v3.address], {
    value: ethers.parseEther("80000000"),
  });

  return await mockDpos.waitForDeployment();
}

export async function deployLara(
  deployer: SignerWithAddress,
  stTaraAddress: string,
  mockDposAddress: string,
  apyOracleAddress: string,
  treasuryAddress: string
) {
  const Utils = await ethers.getContractFactory(ContractNames.utils);
  const utils = await Utils.deploy();
  const utilDeployment = await utils.waitForDeployment();
  const Lara = await ethers.getContractFactory(ContractNames.lara, {
    libraries: {
      Utils: await utilDeployment.getAddress(),
    },
  });
  const lara = await Lara.deploy(
    stTaraAddress,
    mockDposAddress,
    apyOracleAddress,
    treasuryAddress
  );

  const laraDeployment = await lara.waitForDeployment();
  const oracleContract = await ethers.getContractAt(
    ContractNames.apyOracle,
    apyOracleAddress
  );
  await setLaraAddressForOracle(
    deployer,
    oracleContract,
    await laraDeployment.getAddress()
  );
  return laraDeployment;
}

export async function setLaraAddressForOracle(
  dataFeed: SignerWithAddress,
  apyOracle: ApyOracle,
  laraAddress: string
) {
  await apyOracle.connect(dataFeed).setLara(laraAddress);
}
