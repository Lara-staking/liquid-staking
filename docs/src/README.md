# Lara - Liquid Staking For Taraxa

## Introduction

Lara is a liquid staking solution for Taraxa. It allows users to stake their TARA tokens and receive a 1:1 representation of their staked tokens on the Taraxa blockchain. These tokens are called stTARA (staked TARA). stTARA can be used in the Taraxa ecosystem, for example, to provide liquidity on DEXes or to participate in other DeFi protocols. stTARA can be redeemed for TARA at any time.

## Solidity API

Solidity API is available in the following [Docs](docs/index.md).

## Lara Whitepaper

The Lara Protocol detailed documentation & `LARA` token whitepaper can be found [here](https://docs.laraprotocol.com).

## Commands

To pull the latest submodules:

```bash
forge install
```

To compile the contracts:

```bash
make compile
```

or

```bash
forge compile
```

To run the tests:

```bash
make test
```

## Complier version

Details can be found in the [Compilers](COMPILERS.md) file.

## Official Lara Protocol deployments

### Mainnet

#### Lara Token

Lara token deployed on mainnet at address `0xE6A69cD4FF127ad8E53C21a593F7BaC4c608945e`.

#### Lara Staking

The `veLARA` + `LaraStaking` contracts are not deployed on mainnet as of now.

#### Lara Protocol

**Note**: There is no official Lara Protocol deployed on mainnet as of now.

### Testnet

#### Lara Token

Lara token deployed on testnet at address `0x76D53afeb9Fa7Fe37Ebaa7AF1438FF98291d2224`.

#### Lara Staking

The `veLARA` + `LaraStaking` contracts are deployed on testnet at the addresses:

```bash
  veLara token deployed at address: 0xD0Ab112cEDE5b2D8EEAa8a09dA66Bef2110b3038
  Staking contract deployed at address: 0x0d4dBAeEa3Fd95a73E11724aAB2d2Dc3E969E177
  Staking implementation deployed at address: 0x9a78148d4022f0150Eb6Eb3Dccf7e2488cE65c31
```

The Staking contract is funded with 1M veLARA tokens via the `0xe2135516c3d550ff98da77d1fd925aa69ed9cc271346bafdee8c3eafa0cdccb3` transaction .

#### Lara Protocol

Lara Protocol is deployed on testnet at the addresses:

```bash
  stTara address: 0x3A9302b0d2029fCBa5BDCd5CC288F78c7c2C2F09
  oracleProxy address: 0xd6F1DbeC984e845d6088Ca9de6cdfD6670F2c300
  oracleImplementation address: 0xd527F65aac850285A01b9De45e5d8Ec4A80d9A35
  laraProxy address: 0x2057B7D8Cf6C5750e018F69C49dd65e5454e1016
  laraImplementation address: 0xb5B845b28d6722710caBFc3b7FA54b170F7D2b2c
```

## Compiler versions

The development solidity version is `0.8.20`.

The development evm version is `berlin`.

**Note**: The compiler version must be explicitly set in the `foundry.toml` file for effective management. Please check the [foundry.toml](foundry.toml) file for the exact version as well as for more details.

### Upgradable contracts

We need additional metadata for usage of upgradable contracts and their management with the `openzeppelin-foundry-upgrades` package.

We need to define the `build_info`, `extra_output` and add the `node_modules` under the `libs` key.

```toml
[profile.default]
build_info = true
extra_output = ["storageLayout"]
solc =  "0.8.20"
evm_version = 'berlin'
src = 'contracts'
out = 'out'
libs = ['node_modules', 'lib']
test = 'test'
script = 'scripts/foundry'
cache_path  = 'cache_forge'
fs_permissions = [{ access = "read", path = "./"}]
```

## License

Lara is licensed under the [MIT License](LICENSE).
