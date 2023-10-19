🚧🚧🚧🚧 **Repo in active development, expect things to break and change.** 🚧🚧🚧🚧

# Story Protocol Contracts

# Architecture Diagram
![image](https://github.com/storyprotocol/protocol-contracts/assets/2632384/ce60fecc-1904-4c35-a4c1-577c90060feb)

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

Since this is an ERC721, ownership of the Franchise could be determined by an EOA, Multisig, Governor contracts or whatever available web3 coordination tool.


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

To save in gas, these contracts will be proxies, currently BeaconProxy clones 🚧

# Modules

We have represented the IP with our Core Components. Now let's look into the contracts that add utility and features to manage IP in Story Protocol:


## Relationships

A Relationship is an on-chain directional association between 2 IPAssets (or an IPAsset and an external NFT), identified by an ID and a set of pre conditions that gives it meaning.

Relationships can have **previous steps**, defined by **RelationshipProcessor** contracts, that can be built to:

- Check ownership over IPAssets being related.
- Require payment in native currency, ERC20s...
- Require the approval of the owner of one of the IPA
- Any other interaction with other protocols, oracles...

Since they are on-chain, they help compose with other modules or external protocols/contracts:
- They can be created as a result of the execution of other modules (e.g agreeing on the Licensing terms for a Character creates an APPEARS_IN relationship between Character and Story)
- They can be a condition for the correct execution of a module (IPA owner can emit commercial license of a Character IPA if said IPA has a EXTERNAL_PFP relation)
- They can just have narrative meaning within the Franchise (two characters DID_HOOKUP, a story IS_SEQUEL of another) or some other community interation.

There is going to be 2 levels for Relationships:
- Protocol-wide relationships, defined by Governance and with interaction with protocol modules
- Franchise level relationships, to be defined by Franchise Owner 🚧

Protocol-wide relationships need to be proposed through a governance process, [like this one](https://github.com/storyprotocol/protocol-contracts/issues/33)

A system to dispute and revoke Relationships is in the works 🚧

## Licensing

The Licensing Module is at the heart of Story Protocol. It aims to create a transparent, public and fair legal environment for Franchise Owners and Creators to develop an IP while capturing the value and ownership among different contributors in a novel way.

It has several component contracts:

### RightsManager
Every IPAssetRegistry is a RightsManager, which implements a modified version of [draft EIP-5218](https://eips.ethereum.org/EIPS/eip-5218).

It manages trees of License structs and all their sublicenses. If a License is revoked (every License has a revoker address), all the licenses down the tree will be too.

Every License can have none or many on-chain an off-chain terms, and both will be able to be composed from many "License Legos" 🚧
- **Off-chain terms** are given by the License metadata and legal text files linked to the License struct (in the works, based in the Token Bound License)🚧. Off-chain terms will be enforced via a market of licensing flagger/revoker services, individuals and oracles or in worst case scenario, the legacy legal system.
- **On-chain terms** are TermsProcessor contracts, that must be executed by the current License Holder in order to activate the License. These can include:
    - Time limitations, with or without renewal.
    - Setting revenue splits in the Royalty Module.
    - Payment.
    - Approval of the content by the licensor.
    - Creation or check for existance of a Relationship between assets.
    - External NFT ownership
    - KYC Oracle
    - Other cases build by the community

A RightsManager allows us to grant 2 **type of License:**

1. **Rights**: Licenses tied to a tokenId (IPAsset id), in which the license holder is always the owner of said tokenId. Each tokenId can have commercial or non commercial license tied to it. Transfering an IPAsset transfers the Rights too, so the previous owner will lose the ownership of the righst along the IPA.
2. **Tradeable Licenses**: The license holder is the owner of the correspondent LicenseRegistry NFT. They are either:

    a. **Franchise root license**: license minted by a Franchise owner to govern commercial or non commercial rights for all the IPAssetRegistries.

    b. **Sublicense**: a license coming from IPA Rights or other Licenses, minted as an ERC721 by the parent license owner. These would be the future "movie adaptation to my story" or "merchandise rights for my PFP" type licenses that can be transferred or sold in NFT markets.

### LicenseRegistry

Simple ERC721 NFT wrapper for Tradeable Licenses registered in a RightsManager. Each IPAssetRegistry have its correspondent LicenseRegistry.

### Licensing Module

Networked IPs with multiple stakeholders need to have compatible licensing terms and characteristics in order to be commercially develop in a feasible way.
The Licensing Module contract is where Franchise Owners define this common legal framework.

By design, with the idea of growing the IP, every IPA will have a license that will **allow remixing it as long as the remixer**:
- Attributes the original creator
- It's for non commercial (or within reasonable commercial assumptions 🚧)
- It's minted back to the Franchise as a child IPA with the same non commercial terms

Root IPAs have optional commercial rights, meaning that a commercial License might be bought/requested from the owner of the rights, to do a commercial remixes, adaptations, merch, etc, with benefits traversing as defined by revenue/royalty modules. 

**The configurable options are:**

- For both commercial and non commercial rights of IPAs
  - can they sublicense (remix)?
  - do they have a Franchise level root License from which all the rights stem from?
- Terms for both commercial and non commercial rights
- Do root IPA have commercial rights on mint or not?
- URI pointing to the Franchise Commercial Rights license text.

We are going to have several **ready-made templates** for Franchise creators 🚧:

- **Tight narrative/commercial direction:**
  - Commercial Licenses can only be granted by the owner of the Root Commercial License (minted by Franchise Owner)
  - Users can add and remix IPAs under Non Commercial terms.
  - If Franchise Owner wants to emit commercial licenses from IPAs, an agreement must be made between IPA and Franchise owners (inclusion in upside/revenue, up front payment, voting rights, combination of some of all...)
  
- **Loose narrative/commercial direction:**
  - Every root IPA has commercial rights (under some terms, e.g owner of IPA is owner of external PFP NFT) and can emit commercial licenses around that IPA.


## Collect

Collect module allows users to mint duplicates of an IPA as a memento, way of supporting the creators, engagement metric...

- Each IPA can configure custom CollectNFTs as result of the Collect action
- Programable pre conditions for collection will be possible 🚧 (payment, approval)


## Royalties Module

Although revenue/royalties is a complicated subject, we are building infrastructure to make it easier for proyects, since correct incentivization of participants in IP creation is such a core issue in web3 and the off chain enternainment industry.

NOTE: We are using royalties and revenue in an informal and interchangeable way. This is a system to distribute shares of value, the technical source of it is out of scope at the moment. 🚧

The first obvious case that can be enforced with these contracts are on-chain revenue and royalties, but we expect the community to build bridges to more traditional platforms and payment rails that can route value here.

The RoyaltyDistributor contract allows IPAsset owners and license TermsProcessors to set revenue/royal shares.

How the shares are configured is up to RoyaltyPolicies, and the actual shares are given by our RoyaltyNFT, an ERC-1155 wrapper over the [Split contracts of 0xSplits](https://www.0xsplits.xyz/)


# Deployed Contracts
- [Goerli addresses](https://github.com/storyprotocol/protocol-contracts/blob/main/deployment-5.json)

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

Upload Story Blocks and Relationships

This section requires more detail to establish how to format an input JSON data file. In the file, the data should be separated under "ip-assets" and "relationships".

The IP Assets are stored in arrays and represented as JSON objects. For each story block, the following fields are required:
```
// example:
stories: [
// this is an individual story to be uploaded.
{
    "id": null,
    "ipAssetType": "STORY",
    "name": "The Full Grain World Bible",
    "description": "Lorem Ipsum",
    "mediaURL": "https://www.youtube.com/watch?v=9bZkp7q19f0"
}
]
```

The ID is initially set to null to identify an IPAsset that is yet to be uploaded; the file will be rewritten once blocks are successfully uploaded. This means, once the script finished if some batch txs failed, running the script again will only try to upload the failed IP Assets (since it skips ids that are not null)

To upload relationships, the following fields are needed:

```
"relationships": [
    {
      "sourceContract": "same", // Address of the source contract, or "same" if it's the franchise passed as parameter
      "sourceAssetType": "stories", // key for the source IPA data array in the JSON
      "sourceAssetIndex": 0, // Index of the source IPA in the array correspondent to the key above
      "destContract": "same", // Address of the destination contract, or "same" if it's the franchise passed as parameter
      "destAssetType": "characters", // key for the destination IPA data array in the JSON
      "destAssetIndex": 0, // Index of the destination IPA in the array correspondent to the key above
      "data": "0x", // Hook params, if any
      "name": "TEST_RELATIONSHIP", // Name of the relationship, as per SPIP
      "ttl": 1, // Int, duration in seconds of the relationship, in case it can be time limited. Ignored otherwise
      "sourceId": null, //null in the beginning since the IPAs are not uploaded, will be set by the script
      "destId": null, //null in the beginning since the IPAs are not uploaded, will be set by the script
      "relationshipId": null //null in the beginning since relationship is unset, it will be the hash of name.
    }
  ]
```

[The full example JSON is in script/data/data_example.json](/script/data/data_example.json)

To call the task, use the following:
```
npx hardhat --network <network> -sp:uploader <franchiseId> <address that receives the IPAs> <pathname of JSON data> --batchSize <optional number of entried batched per tx>
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


