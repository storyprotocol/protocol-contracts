const { readFileSync } = require("fs");

const DEBUG = false;

async function main(hre) {
    const { ethers } = hre;
    const chainId = await ethers.provider.getNetwork().then((n) => n.chainId);
    console.log("ChainId:", `${chainId}`);
    
    const filePath = `./deployment-${chainId}.json`;
    const deployment = JSON.parse(readFileSync(filePath));
    if (DEBUG) {
        Object.keys(deployment).forEach((key) => {
            console.log(`${key}: ${deployment[key]}`);
        });
    }
    const contracts = {}
    contracts.FranchiseRegistry = await ethers.getContractFactory("FranchiseRegistry");
    contracts.franchiseRegistry = await contracts.FranchiseRegistry.attach(deployment.main["FranchiseRegistry-Proxy"]);
    contracts.IPAssetsRegistry = await ethers.getContractFactory("IPAssetRegistry");
    contracts.IPAssetEventEmitter = await ethers.getContractFactory("CommonIPAssetEventEmitter");
    contracts.ProtocolRelationshipModule = await ethers.getContractFactory("ProtocolRelationshipModule");
    contracts.relationshipModule = await contracts.ProtocolRelationshipModule.attach(deployment.main["ProtocolRelationshipModule-Proxy"]);
    contracts.LicensingModule = await ethers.getContractFactory("LicensingModule")
    return { chainId, contracts, deployment };
}

module.exports = main;
