-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil zktest

build:
	forge build

deploy-sepolia:
	forge script script/DeployFundMe.s.sol:DeployFundMe --rpc-url $(SEPOLIA_RPC_URL) --account $(SEPOLIA_ACCOUNT) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
