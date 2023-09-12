# Story Protocol Contracts

# Architecture Diagram
![image](https://github.com/storyprotocol/protocol-contracts/assets/2632384/b3912a23-adb9-4fd2-98b7-922e48a6ebb4)

# Core Components

In Story Protocol, the basic unit of intellectual property is the IPAsset, representing a well defined item that will be subject to a set of rules defined in each Franchise.
IPAssets will have many categories corresponding to different domains of intellectual property, starting with Narrative Universes.

The starting IPAsset types are:
- Story
- Character
- Item
- Location
- Art
- Group

They have mediaURL, an off chain file identifying the IPA medium, duration, divisions, authorship and other characteristics.

IPAssets can be combined together to form more rich intellectual property, and can be remixed and extended within the legal parameters defined on each Franchise.

## FranchiseRegistry

ERC721 that registers all the narrative franchises in Story Protocol.
When registering a new franchise, along with minting an NFT to identify the Franchise Owner, all contracts required to represent the IPAssets, their IP rights, licenses, etc will be deployed by a factory.

Ownership of a Franchise Registry token implies the power to:
- Configure the licensing rules for the IPAssets created in the Franchise
- Define possible Relationships between IPAssets of the same franchise 🚧


## IPAssetRegistry

ERC721 NFT where IPAssets are minted. There is 1 IPAssetRegistry per Franchise registered in Story Protocol.

When minted, an IPAsset will also:
1. Set it's metadata
2. Set the parent IPA id, in case it is a remix
3. Assign the licenses representing its IP Rights, as defined by the Franchise Owner in the Licensing Module.
4. Configure it's collectible 🚧


## IPAssetRegistryFactory

Factory contract responsible for, when triggered by a Franchise registration, deploying an instance of the contracts required to represent and run said Franchise:
- IPAssetRegistry
- LicenseRegistry

To save in gas, these contracts will be proxys, currently BeaconProxy clones 🚧

# Modules

We have represented the IP with our Core Components. Now let's look into the contracts that add utility and features to manage IP in Story Protocol:


## Relationships

A Relationship is an on-chain directional association between 2 IPAssets (or an IPAsset and an external NFT), identified by an ID and a set of pre conditions that gives it meaning.

Since they are on-chain, they help compose with other modules or external protocols/contracts:
- They can be created as a result of the execution of other modules (e.g agreeing on the Licensing terms for a Character creates an APPEARS_IN relationship between Character and Story)
- They can be a condition for the correct execution of a module (IPA owner can emit commercial license of a Character IPA if said IPA has a EXTERNAL_PFP relation)


## Licensing

## Collect

## Royalty Splits



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

# Deploying to a network

## Setup

You'll need to add the following variables to a `.env` file:

-   `MAINNET_RPC_URL`
-   `MAINNET_PRIVATEKEY`
-   `GOERLI_RPC_URL`
-   `GOERLI_PRIVATEKEY`
-   `ETHERSCAN_API_KEY`

## Deploying

Deploy local
```
anvil
(open other tab)
forge script script/foundry/Deploy.s.sol:Deploy --fork-url=http://127.0.0.1:8545 
```

Deploy to network dry run
```
forge script script/Deploy.s.sol:Deploy --fork-url=<network rpc url url> -vvvv
```

Deploy to network
```
forge script script/foundry/Deploy.s.sol:Deploy --fork-url=<network rpc url url> -vvvv --broadcast --verify
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
We employed solhint to check code style.
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


## Resources
-   [Hardhat](https://hardhat.org/docs)
-   [Foundry Documentation](https://book.getfoundry.sh/)
-   [Yarn](https://yarnpkg.com/getting-started)


