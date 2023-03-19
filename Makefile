-include .env

install:
	forge install Openzeppelin/openzeppelin-contracts foundry-rs/forge-std Openzeppelin/openzeppelin-contracts-upgradeable smartcontractkit/chainlink

clean:
	remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

tests:
	forge test -vvvv

# Scripts

deploy-blueprint:
	forge script script/1.Blueprint.s.sol:StoreScript --rpc-url ${RPC_URL} --etherscan-api-key ${EXPLORER_KEY} --broadcast --verify -vvvv

deploy-manager:
	forge script script/2.StoreManager.s.sol:StoreManagerScript --rpc-url ${RPC_URL} --etherscan-api-key ${EXPLORER_KEY} --broadcast --verify -vvvv

deploy-factory:
	forge script script/3.StoreFactory.s.sol:StoreFactoryScript --rpc-url ${RPC_URL} --etherscan-api-key ${EXPLORER_KEY} --broadcast --verify -vvvv

set-lambda:
	forge script script/SetLambda.s.sol:SetLambdaScript --rpc-url ${RPC_URL} --broadcast --verify -vvvv

deploy-new-store:
	forge script script/CreateStore.s.sol:CreateStoreScript --rpc-url ${RPC_URL} --broadcast --verify -vvvv

store:
	forge script script/Store.s.sol:StoreScript --rpc-url ${RPC_URL} --broadcast --verify -vvvv

upgrade-manager:
	forge script script/UpgradeStoreManager.s.sol:UpgradeStoreManagerScript --rpc-url ${RPC_URL} --etherscan-api-key ${EXPLORER_KEY} --broadcast --verify -vvvv