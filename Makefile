-include .env

.PHONY: all test clean coverage

all: clean install build

# Clean the repo
forge-clean  :; forge clean
clean  :; npx hardhat clean

# Remove modules
forge-remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; npm install

# Update Dependencies
forge-update:; forge update

forge-build:; forge build
build :; npx hardhat compile

# TODO: remove --no-match-path after refactor
test :; forge test -vvv --no-match-path 'test/foundry/_old_modules/*' 

snapshot :; forge snapshot

slither :; slither ./contracts

format :; npx prettier --write --plugin=prettier-plugin-solidity 'contracts/**/*.sol' && npx prettier --write --plugin=prettier-plugin-solidity --write 'contracts/*.sol'

# remove `test` and `script` folders from coverage
coverage:
	mkdir -p coverage
	forge coverage --report lcov
	lcov --remove lcov.info -o lcov.info 'test/*' 'script/*'
	genhtml lcov.info --output-dir coverage

# solhint should be installed globally
lint :; npx solhint 'contracts/**/*.sol'

deploy-goerli :; npx hardhat run ./script/deploy-reveal-engine.js --network goerli
verify-goerli :; npx hardhat verify --network goerli ${contract}

anvil :; anvil -m 'test test test test test test test test test test test junk'

