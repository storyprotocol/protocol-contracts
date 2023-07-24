const { readFileSync } = require("fs");

const DEBUG = false;

async function main(hre) {
    const { ethers } = hre;
    const chainId = await ethers.provider.getNetwork().then((n) => n.chainId);
    console.log("ChainId:", `${chainId}`);
    const filePath = chainId === 31337 ? "./deployment-local.json" : "./deployment-public.json";
    const deployment = JSON.parse(readFileSync(filePath))[`${chainId}`];
    if (DEBUG) {
        Object.keys(deployment).forEach((key) => {
            console.log(`${key}: ${deployment[key]}`);
        });
    }
    const contracts = {}
    contracts.FranchiseRegistry = await ethers.getContractFactory("FranchiseRegistry");
    contracts.franchiseRegistry = await contracts.FranchiseRegistry.attach(deployment["FranchiseRegistry-Proxy"]);
    contracts.IPAssetsRegistry = await ethers.getContractFactory("IPAssetsRegistry");
    contracts.ProtocolRelationshipModule = await ethers.getContractFactory("ProtocolRelationshipModule");
    contracts.protocolRelationshipModule = await contracts.ProtocolRelationshipModule.attach(deployment["ProtocolRelationshipModule-Proxy"]);
    
    return { chainId, contracts, deployment };
}

module.exports = main;
