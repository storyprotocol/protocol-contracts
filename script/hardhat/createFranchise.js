const loadDeployment = require('./loadDeployment.js');
const { getContractAddress } = require('@ethersproject/address');

function findIdAndAddress(events) {
    const event = events.find((e) => e.event === "FranchiseRegistered");
    return {
        id: event.args.id.toString(),
        address: event.args.storyBlockRegistryForId,
    };
}

async function main(args, hre) {
    const { ethers } = hre;
    const { chainId, contracts } = await loadDeployment(hre);
    const { name, symbol, description, events } = args;
    console.log("Creating franchise: ", name, symbol);
    const tx = await contracts.franchiseRegistry.registerFranchise(name, symbol, description);
    console.log("Franchise created in tx: ", tx.hash);
    console.log("Waiting for tx to be mined...");
    const receipt = await tx.wait();
    if (events) {
        console.log("Events: ");
        console.log(receipt.events);
    }
    console.log("Franchise created");
    const { id, address } = findIdAndAddress(receipt.events);
    console.log("id: ", id);
    console.log("address: ", address);
    return { id, address };
}

module.exports = main;
