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
  lara token address: 0x2915BcAfd018c5b7B7FA0730a4CE0e42772d145F
  stTara address: 0xe9e0B9960fD410f84d095eeaa5e4e6e8fE7e1aDA
  oracleProxy address: 0xd170c33a27A9C3cb599d9B41970DAD2AaCeE96e2
  oracleImplementation address: 0xE6C2a1fEA67ea93A7Ce415672dFDb95B35e17d8E
  laraProxy address: 0x397F45dCaC0DC00cb927d8eCE7d449F726A517cF
  laraImplementation address: 0xCDc0909a9d11E3D7F51e3B94bDC8ad7d31D76bBD
```

### PRnet details

- RPC: `https://rpc-pr-2609.prnet.taraxa.io`
- Explorer: `https://explorer-pr-2609.prnet.taraxa.io`
- ChainId: `200`
- Name: `Taraxa PRnet-2609`
- Currency: `TARA`
