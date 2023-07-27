const loadDeployment = require('./loadDeployment.js');
const { getIPAssetRegistryAddress } = require('./getIPAssetRegistryAddress.js');

function findId(events) {
    const event = events.find((e) => e.event === "Transfer");
    return event.args.tokenId.toString()
}

function validateIPAssetType(IPAssetType) {
    console.log("IPAssetType: ", IPAssetType);
    switch (IPAssetType) {
        case "STORY":
            return 1;
        case "CHARACTER":
            return 2;
        case "ART":
            return 3;
        case "GROUP":
            return 4;
        case "LOCATION":
            return 5;
        case "ITEM":
            return 6;
        default:
            throw new Error("Invalid story block type: " + IPAssetType);
    }
}

async function main(args, hre) {
    const { ethers } = hre;
    const { chainId, contracts } = await loadDeployment(hre);
    const { franchiseId, ipAssetType, name, description, mediaURL, events } = args;
    console.log(args)
    console.log(ipAssetType)
    const sbType = validateIPAssetType(ipAssetType);
    console.log("sbType: ", sbType);
    const { address } = await getIPAssetRegistryAddress(ethers, franchiseId, contracts);
    
    const IPAssetRegistry = await contracts.IPAssetsRegistry.attach(address);
    console.log("Creating story block: ", ipAssetType, name, description, mediaURL);
    const tx = await IPAssetRegistry.createIPAsset(sbType, name, description, mediaURL);
    console.log("tx: ", tx.hash);
    console.log("Waiting for tx to be mined...");
    const receipt = await tx.wait();
    if (events) {
        console.log("Events: ");
        console.log(receipt.events);
    }
    const id = findId(receipt.events);
    console.log("Story block created: ", id);
    
    return { id };
}

module.exports = main;
module.exports.validateIPAssetType = validateIPAssetType;
