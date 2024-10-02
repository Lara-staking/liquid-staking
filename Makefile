.PHONY: compile test-all test foundry-test lint docgen \
        deploy-apy-testnet deploy-apy-mainnet deploy-stats-mainnet deploy-stats-testnet \
        deploy-lara-testnet prnet-deploy-lara deploy-only-lara-testnet deploy-lara-devnet \
        stake-lara-testnet lara-token-devnet lara-token-testnet lara-token-mainnet \
        lara-token-prnet stake-lara-devnet dpos-devnet update-top100-validators delegate \
        multicall-deploy

compile:
	forge test

test:
	forge test -vv --ffi --force

lint:
	yarn run eslint . --ext .ts

deploy-lara-testnet:
	forge script /Users/vargaelod/lara/liquid-staking/scripts/Lara.s.sol:DeployLara --rpc-url https://rpc.testnet.taraxa.io --broadcast --legacy -vvvv --ffi

prnet-deploy-lara:
	forge script /Users/vargaelod/lara/liquid-staking/scripts/Lara.s.sol:DeployLara --rpc-url https://rpc-pr-2609.prnet.taraxa.io --broadcast --legacy -vvvv --ffi

deploy-only-lara-testnet:
	forge script /Users/vargaelod/lara/liquid-staking/scripts/OnlyLara.s.sol:DeployLara --rpc-url https://rpc.testnet.taraxa.io --broadcast --legacy -vvvv --ffi

deploy-lara-devnet:
	forge script /Users/vargaelod/lara/liquid-staking/scripts/Lara.s.sol:DeployLara --rpc-url https://rpc.devnet.taraxa.io --broadcast -vvvv --ffi

stake-lara-testnet:
	forge script /Users/vargaelod/lara/liquid-staking/scripts/Delegate.s.sol:Delegate --rpc-url https://rpc.testnet.taraxa.io --broadcast --legacy -vvvv --ffi

lara-token-devnet:
	forge script /Users/vargaelod/lara/liquid-staking/scripts/TokenLara.s.sol:DeployLaraToken --rpc-url https://rpc.devnet.taraxa.io --broadcast --legacy -vvvv --ffi

lara-token-testnet:
	forge script /Users/vargaelod/lara/liquid-staking/scripts/TokenLara.s.sol:DeployLaraToken --rpc-url https://rpc.testnet.taraxa.io --broadcast --legacy -vv --ffi --slow

lara-token-mainnet:
	forge script /Users/vargaelod/lara/liquid-staking/scripts/TokenLara.s.sol:DeployLaraToken --rpc-url https://rpc.mainnet.taraxa.io --broadcast --legacy -vvvv --ffi --verify --verifier sourcify

lara-token-prnet:
	forge script /Users/vargaelod/lara/liquid-staking/scripts/TokenLara.s.sol:DeployLaraToken --rpc-url https://rpc-pr-2609.prnet.taraxa.io --broadcast --legacy -vvvv --ffi

stake-lara-devnet:
	forge script /Users/vargaelod/lara/liquid-staking/scripts/Delegate.s.sol:Delegate --rpc-url https://rpc.devnet.taraxa.io --broadcast --legacy -vvvv --ffi

dpos-devnet:
	forge script /Users/vargaelod/lara/liquid-staking/scripts/Dpos.s.sol:DposTest --rpc-url https://rpc.devnet.taraxa.io --broadcast --legacy -vvvv --ffi

multicall-deploy:
	forge script /Users/vargaelod/lara/liquid-staking/scripts/DeployMulticall.s.sol:DeployMulticall --rpc-url https://rpc-pr-2609.prnet.taraxa.io --broadcast --legacy -vvvv --ffi