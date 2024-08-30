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
  stTaraProxy address: 0xB576261E50858Caaf4C072Fd20f9fd690109C69a
  stTaraImplementation address: 0xb5a7371e444f58f93B718b6b56c0720C6A6F26DB
  oracleProxy address: 0x58D1Ac0a2b6003F6986191F024Ed7bC5d7d4c0da
  oracleImplementation address: 0x0720Efbf82B1EE940978435373322D0aDD0412d1
  laraProxy address: 0x017bcd6c818baeee80809E21786fcAA595d75eB2
  laraImplementation address: 0xCA43A118336e915D807aa99B7A41b533881FE611
```

### PRnet details

- RPC: `https://rpc-pr-2609.prnet.taraxa.io`
- Explorer: `https://explorer-pr-2609.prnet.taraxa.io`
- ChainId: `200`
- Name: `Taraxa PRnet-2609`
- Currency: `TARA`
