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
const defenderUpdateContracts = require("./script/hardhat/defenderUpdateContracts.js");
const { task } = require("hardhat/config");

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

task('sp:defender:update-contracts')
    .setDescription('Uploads contract data to Defender')
    .setAction(defenderUpdateContracts);

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
  },
  docgen: {
    outputDir: "./docs",
    pages: "files"
  }
};
