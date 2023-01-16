-include .env

install:
	forge install Openzeppelin/openzeppelin-contracts foundry-rs/forge-std Openzeppelin/openzeppelin-contracts-upgradeable smartcontractkit/chainlink --no-commit

clean:
	remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

tests:
	forge test -vvvv

# run anvil in another terminal
script-local:
	forge script script/Counter.s.sol:CounterScript --fork-url http://localhost:8545 --private-key ${PRIVATE_LOCAL_KEY} --broadcast -vvvv