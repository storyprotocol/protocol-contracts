require("dotenv").config();
require('hardhat-deploy');

require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-waffle");
require("hardhat-gas-reporter");
require("solidity-coverage");
require('@nomiclabs/hardhat-ethers');
require("@nomiclabs/hardhat-etherscan");
require('@openzeppelin/hardhat-upgrades');
require('solidity-docgen');

const namespacedStorageKey = require("./script/hardhat/namespacedStorageKey.js");
const defenderAdminProposal = require("./script/hardhat/defender/adminProposal.js");

const { task } = require("hardhat/config");

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

task('sp:defender:admin-proposal')
    .addPositionalParam('proposalFileName', 'Name of the proposal file in scripts/hardhat/proposals, without .js extension')
    .setDescription('Creates a proposal on Defender, to be signed by the multisig')
    .setAction(defenderAdminProposal);

task('sp:eip7201-key')
    .addPositionalParam('namespace', 'Namespace, for example erc7201:example.main')
    .setDescription('Get the namespaced storage key for https://eips.ethereum.org/EIPS/eip-7201')
    .setAction(namespacedStorageKey);

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
    sepolia: {
      url: process.env.SEPOLIA_RPC_URL || "",
      chainId: 11155111,
      accounts: [process.env.SEPOLIA_PRIVATEKEY || "0x1234567890123456789012345678901234567890123456789012345678901234"]
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
  },
  docgen: {
    outputDir: "./docs",
    pages: "files"
  }
};
