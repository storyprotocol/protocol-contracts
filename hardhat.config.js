require("dotenv").config();
require('hardhat-deploy');

require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-waffle");
require("hardhat-gas-reporter");
require("solidity-coverage");
require('@nomiclabs/hardhat-ethers');
require("@nomiclabs/hardhat-etherscan");
require('@openzeppelin/hardhat-upgrades');

const createFranchise = require("./script/hardhat/createFranchise.js");
const createStoryBlock = require("./script/hardhat/createStoryBlock.js");
const getStoryBlockRegistryAddress = require("./script/hardhat/getStoryBlockRegistryAddress.js");
const getStoryBlock = require("./script/hardhat/getStoryBlock.js");

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

task('sp:create-franchise')
    .addPositionalParam('name', 'Franchise name')
    .addPositionalParam('symbol', 'Franchise symbol')
    .addPositionalParam('description', 'Franchise description')
    .setDescription('Mint Franchise NFT and create StoryBlocksRegistry contract')
    .setAction(createFranchise);

task('sp:get-story-block-registry-address')
    .addPositionalParam('franchiseId', 'Id of the Franchise to create the Story Block in, as given by FranchiseRegistry contract')
    .setDescription('Get the address of the StoryBlocksRegistry contract for the given Franchise')
    .setAction(getStoryBlockRegistryAddress);

task('sp:create-block')
    .addPositionalParam('franchiseId', 'Id of the Franchise to create the Story Block in, as given by FranchiseRegistry contract')
    .addPositionalParam('storyBlockType', 'STORY, CHARACTER, ART, GROUP, LOCATION or ITEM')
    .addPositionalParam('name', 'Story Block name')
    .addPositionalParam('description', 'Story Block description')
    .addPositionalParam('mediaURL', 'Story Block media URL')
    .setDescription('Mint Story Block NFT and create StoryBlocksRegistry contract')
    .setAction(createStoryBlock);

task('sp:read-block')
    .addPositionalParam('franchiseId', 'Id of the Franchise to create the Story Block in, as given by FranchiseRegistry contract')
    .addPositionalParam('storyBlockId', 'Id of the Story Block to read')
    .setDescription('Get the Story Block details')
    .setAction(getStoryBlock);

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  networks: {
    mainnet: {
      url: process.env.MAINNET_RPC_URL || "",
      chainId: 1,
      accounts: [process.env.MAINNET_PRIVATEKEY || "0x1234567890123456789012345678901234567890123456789012345678901234"]
    },
    goerli: {
      url: process.env.GOERLI_RPC_URL || "",
      chainId: 5,
      accounts: [process.env.GOERLI_PRIVATEKEY || "0x1234567890123456789012345678901234567890123456789012345678901234"]
    },
    local: {
      url: "http://127.0.0.1:8545",
      chainId: 31337,
      accounts: {
        mnemonic: "test test test test test test test test test test test junk",
      }
    }
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 2000
      }
    }
  },
  etherscan: {
    apiKey: `${process.env.ETHERSCAN_API_KEY}`
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  mocha: {
    timeout: 20000
  }
};
