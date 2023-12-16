const { readFileSync } = require("fs");

const DEBUG = false;

async function main(hre) {
    const { ethers } = hre;
    const chainId = await ethers.provider.getNetwork().then((n) => n.chainId);
    console.log("ChainId:", `${chainId}`);
    const contracts = {};

    const filePath = `./deployment-${chainId}.json`;
    const deployment = JSON.parse(readFileSync(filePath))['main'];
    for (let contractName in deployment) {
        if (DEBUG) {
            console.log(`${contractName}: ${deployment[contractName]}`);
        }
        const contractAddress = deployment[contractName];
        if (contractName.endsWith('-Proxy')) {
            contractName = contractName.replace('-Proxy', '');
        } else if (contractName.endsWith('-Impl') || contractName === 'MockERC721') {
            continue;
        }

        contracts[contractName] = await ethers.getContractAt(contractName, contractAddress);
    }

    return { chainId, contracts, deployment };
}

module.exports = main;
