# Lara - Liquid Staking For Taraxa

## Introduction

Lara is a liquid staking solution for Taraxa. It allows users to stake their TARA tokens and receive a 1:1 representation of their staked tokens on the Taraxa blockchain. These tokens are called stTARA (staked TARA). stTARA can be used in the Taraxa ecosystem, for example, to provide liquidity on DEXes or to participate in other DeFi protocols. stTARA can be redeemed for TARA at any time.

## Solidity API

Solidity API is available in the following [Docs](docs/index.md).

## License

Lara is licensed under the [MIT License](LICENSE).

## Commands

To pull the latest submodules:

```bash
forge install
```

To compile the contracts:

```bash
yarn compile
```

or

```bash
forge compile
```

To run the tests:

```bash
yarn test:all
```

## Lara Protocol is available on a Taraxa PRnet at the following addresses

```bash
  stTaraProxy address: 0xe01095F5f61211b2daF395E947C3dA78D7a431Ab
  stTaraImplementation address: 0x181E53969652b3F1D2c82AF546B9AE11B3516a98
  oracleProxy address: 0x4bFCdc5a4166405D9503437523832Bbd2DC759Ef
  oracleImplementation address: 0xC938B8a781b6cFfEcb6A9170e4221C4D146c01d6
  laraProxy address: 0x52a7C8Db4a32016e4b8b6b4b44590C52079f32A9
  laraImplementation address: 0x7409A03005AFe903C9e847c93421DEF0458b851b
```

### PRnet details

RPC: `https://rpc-pr-2609.prnet.taraxa.io`
Explorer: `https://explorer-pr-2609.prnet.taraxa.io`
ChainId: `200`
Name: `Taraxa PRnet-2609`
Currency: `TARA`
