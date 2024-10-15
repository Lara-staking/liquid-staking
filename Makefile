.PHONY: compile test-all test foundry-test lint docgen deploy help

RPC_TESTNET := https://rpc.testnet.taraxa.io  
RPC_DEVNET := https://rpc.devnet.taraxa.io  
RPC_PRNET := https://rpc-pr-2609.prnet.taraxa.io  
RPC_MAINNET := https://rpc.mainnet.taraxa.io

compile:
	forge test

test:
	forge test -vv --ffi --force

lint:
	yarn run eslint . --ext .ts

docgen:
	forge doc --build --out docs

# Generalized deploy command
script:
ifndef SCRIPT
	$(error SCRIPT is not set. Use SCRIPT=<script_name> to specify the script)
endif
ifndef ACTION
	$(error ACTION is not set. Use ACTION=<action_name> to specify the action)
endif
ifndef NETWORK
	$(error NETWORK is not set. Use NETWORK=<network_name> to specify the network)
endif
ifndef VERBOSE
	$(warning VERBOSE is not set. Defaulting to VERBOSE=vv)
	VERBOSE=vv
endif
	forge script scripts/$(SCRIPT).s.sol:$(ACTION) --rpc-url $(RPC_$(NETWORK)) --force --ffi --broadcast --legacy -$(VERBOSE)

# Specific targets using the generalized command
deploy-lara-testnet:
	$(MAKE) script SCRIPT=Lara ACTION=DeployLara NETWORK=TESTNET

prnet-deploy-lara:
	$(MAKE) script SCRIPT=Lara ACTION=DeployLara NETWORK=PRNET

deploy-only-lara-testnet:
	$(MAKE) script SCRIPT=OnlyLara ACTION=DeployLara NETWORK=TESTNET

deploy-lara-devnet:
	$(MAKE) script SCRIPT=Lara ACTION=DeployLara NETWORK=DEVNET

deploy-lara-staking-testnet:
	$(MAKE) script SCRIPT=LaraStaking ACTION=DeployLaraStaking NETWORK=TESTNET

stake-lara-testnet:
	forge script scripts/Delegate.s.sol:Delegate --rpc-url $(RPC_TESTNET) --broadcast --legacy -vvvv --ffi

lara-token-devnet:
	forge script scripts/TokenLara.s.sol:DeployLaraToken --rpc-url $(RPC_DEVNET) --broadcast --legacy -vvvv --ffi

lara-token-testnet:
	forge script scripts/TokenLara.s.sol:DeployLaraToken --rpc-url $(RPC_TESTNET) --broadcast --legacy -vv --ffi --slow

lara-token-mainnet:
	forge script scripts/TokenLara.s.sol:DeployLaraToken --rpc-url $(RPC_MAINNET) --broadcast --legacy -vvvv --ffi --verify --verifier sourcify

lara-token-prnet:
	forge script scripts/TokenLara.s.sol:DeployLaraToken --rpc-url $(RPC_PRNET) --broadcast --legacy -vvvv --ffi

stake-lara-devnet:
	forge script scripts/Delegate.s.sol:Delegate --rpc-url $(RPC_DEVNET) --broadcast --legacy -vvvv --ffi

dpos-devnet:
	forge script scripts/Dpos.s.sol:DposTest --rpc-url $(RPC_DEVNET) --broadcast --legacy -vvvv --ffi

multicall-deploy:
	forge script scripts/DeployMulticall.s.sol:DeployMulticall --rpc-url $(RPC_PRNET) --broadcast --legacy -vvvv --ffi

# Help target to print available options
help:
	@echo "\033[1;34mUsage:\033[0m make <target>"
	@echo ""
	@echo "\033[1;34mTargets:\033[0m"
	@echo "  \033[1;32mcompile\033[0m                Compile the project"
	@echo "  \033[1;32mtest\033[0m                   Run tests"
	@echo "  \033[1;32mlint\033[0m                   Run linter"
	@echo "  \033[1;32mscript\033[0m                 Deploy a script"
	@echo "    \033[1;33mSCRIPT=<script>\033[0m      Specify the script name (e.g., Lara, TokenLara)"
	@echo "    \033[1;33mACTION=<action>\033[0m      Specify the action (e.g., DeployLara, DeployLaraToken)"
	@echo "    \033[1;33mNETWORK=<network>\033[0m    Specify the network (e.g., TESTNET, DEVNET, PRNET, MAINNET)"
	@echo "    \033[1;33mVERBOSE=<vv|vvvv|vvvv>\033[0m Specify the verbosity (e.g., vv, vvvv, vvvvv)"
	@echo "  \033[1;32mdeploy-lara-testnet\033[0m    Deploy Lara to TESTNET"
	@echo "  \033[1;32mprnet-deploy-lara\033[0m      Deploy Lara to PRNET"
	@echo "  \033[1;32mdeploy-only-lara-testnet\033[0m Deploy OnlyLara to TESTNET"
	@echo "  \033[1;32mdeploy-lara-devnet\033[0m     Deploy Lara to DEVNET"
	@echo "  \033[1;32mstake-lara-testnet\033[0m     Stake Lara on TESTNET"
	@echo "  \033[1;32mlara-token-devnet\033[0m      Deploy Lara Token to DEVNET"
	@echo "  \033[1;32mlara-token-testnet\033[0m     Deploy Lara Token to TESTNET"
	@echo "  \033[1;32mlara-token-mainnet\033[0m     Deploy Lara Token to MAINNET"
	@echo "  \033[1;32mlara-token-prnet\033[0m       Deploy Lara Token to PRNET"
	@echo "  \033[1;32mstake-lara-devnet\033[0m      Stake Lara on DEVNET"
	@echo "  \033[1;32mdpos-devnet\033[0m            Deploy DPOS to DEVNET"
	@echo "  \033[1;32mmulticall-deploy\033[0m       Deploy Multicall to PRNET"