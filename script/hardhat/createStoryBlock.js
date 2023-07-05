const loadDeployment = require('./loadDeployment.js');
const { getStoryBlockRegistryAddress } = require('./getStoryBlockRegistryAddress.js');

function findId(events) {
    const event = events.find((e) => e.event === "Transfer");
    return event.args.tokenId.toString()
}

function validateStoryBlockType(storyBlockType) {
    switch (storyBlockType) {
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
            throw new Error("Invalid story block type: " + storyBlockType);
    }
}

async function main(args, hre) {
    const { ethers } = hre;
    const { chainId, contracts } = await loadDeployment(hre);
    const { franchiseId, storyBlockType, name, description, mediaURL, events } = args;
    const sbType = validateStoryBlockType(storyBlockType);
    const { address } = await getStoryBlockRegistryAddress(ethers, franchiseId, contracts);
    
    const storyBlockRegistry = await contracts.StoryBlocksRegistry.attach(address);
    console.log("Creating story block: ", storyBlockType, name, description, mediaURL);
    const tx = await storyBlockRegistry.createStoryBlock(sbType, name, description, mediaURL);
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
module.exports.validateStoryBlockType = validateStoryBlockType;
