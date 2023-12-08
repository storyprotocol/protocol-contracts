### 🚧🚧🚧🚧
### WARNING, Alpha version: This code is in active development and unaudited.
### Do not use in Production
### 🚧🚧🚧🚧

[See Alpha agreement if you are going to use these contracts](https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf)

![Logo](image.png)

# Story Protocol Contracts

Story Protocol is a decentralized IP protocol for powering the next wave of creative innovation on the Internet. By providing a decentralized IP registry and a set of powerful modules centered around IP licensing, Story Protocol enables creators to build new forms of IP without the friction imposed by traditional processes.

## Documentation
[See Documenentation](https://docs.storyprotocol.xyz/docs/overview-2)

## Guidelines
[See our contribution guidelines](./GUIDELINES.md)

# Deployed Contracts
- [Sepolia addresses](https://github.com/storyprotocol/protocol-contracts/deployment-11155111.json)

# Installing

## Requirements

Please install the following:

-   [Foundry / Foundryup](https://github.com/gakonst/foundry)
-   [Hardhat](https://hardhat.org/hardhat-runner/docs/getting-started#overview) 

And you probably already have `make` installed... but if not [try looking here.](https://askubuntu.com/questions/161104/how-do-i-install-make) and [here for MacOS](https://stackoverflow.com/questions/1469994/using-make-on-os-x)

## Quickstart

```sh
make # This installs the project's dependencies.
make test
```

## Testing

```
make test
```

or

```
forge test
```

## Coverage

```
make coverage
```
Open `index.html` in `coverage/` folder.

# Deploying to a network

## Setup

Copy .env.example into .env, and set the required variables.

## Deploying

Deploy local
```
anvil
(open other tab)
forge script script/foundry/deployment/Main.s.sol:Main --fork-url=http://127.0.0.1:8545 
```

Deploy to network dry run
```
forge script script/foundry/deployment/Main.s.sol:Main --fork-url=<network rpc url url> -vvvv
```

Deploy to network
```
forge script script/foundry/deployment/Main.s.sol:Main --fork-url=<network rpc url url> -vvvv --broadcast --verify
```

# Tasks
Before using any task, make sure you have run
```
npx hardhat compile
```

NOTE: All task that generate transactions can be called with additional param `--events true ` so they print the tx receipt's events
Create a Franchise
```
npx hardhat --network <networ name> sp:create-franchise -name="Test" -description="Short description" -symbol="TT"
```

Get Franchise Address for ID
```
npx hardhat sp:get-ip-asset-registry-address --network <network> <franchiseId>
```

Create Story Block
```
npx hardhat sp:create-ip-asset --network <network> <franchiseId> <IPAssetType name, like "ART", "STORY"...> <name> <description> "https://www.youtube.com/watch\?v\=dQw4w9WgXcQ"
```

Read Story Block
```
npx hardhat sp:read-ip-asset--network <network> <franchiseId> <IPAssetId>
```

### Working with a local network

Foundry comes with local network [anvil](https://book.getfoundry.sh/anvil/index.html) baked in, and allows us to deploy to our local network for quick testing locally.

To start a local network run:

```
make anvil
```

This will spin up a local blockchain with a determined private key, so you can use the same private key each time.

# Code Style

Defined in our [Guidelines](./GUIDELINES.md)

To check code style with solhint run:
```
make lint
```
To re-format code with prettier run:
```
make format
```

# Security

We use slither, a popular security framework from [Trail of Bits](https://www.trailofbits.com/). To use slither, you'll first need to [install python](https://www.python.org/downloads/) and [install slither](https://github.com/crytic/slither#how-to-install).

Then, you can run:

```
make slither
```

And get your slither output.

# Document Generation

We use [solidity-docgen](https://github.com/OpenZeppelin/solidity-docgen) to generate the documents for smart contracts. Documents can be generated with the following command:

```
npx hardhat docgen
```

By default, the documents are generated in Markdown format in the `doc` folder of the project. Each Solidity file (`*.sol`) has its own Markdown (`*.md`) file. To update the configuration for document generation, you can update the following section in `harhat.config.js`:

```
docgen: {
  outputDir: "./docs",
  pages: "files"
}
```

You can refer to the [config.ts](https://github.com/OpenZeppelin/solidity-docgen/blob/master/src/config.ts) of solidity-docgen for the full list of configurable parameters.

## Resources
-   [Hardhat](https://hardhat.org/docs)
-   [Foundry Documentation](https://book.getfoundry.sh/)
-   [Yarn](https://yarnpkg.com/getting-started)

## License

The primary license for StoryProtocol is the Business Source License 1.1 (`BUSL-1.1`), see [LICENSE](https://github.com/storyprotocol/protocol-contracts/blob/main/LICENSE). Minus the following exceptions:
- [Hooks](./contracts/hooks) and [Base Modules](./contracts/modules/base) have an MIT License
- [Interfaces](./contracts/interfaces) have an MIT license


