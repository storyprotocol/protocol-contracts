const loadDeployment = require('./loadDeployment.js');

async function main(args, hre) {
    const { ethers } = hre;
    const { chainId, contracts } = await loadDeployment(hre);
    const { sourceContract, sourceId, destContract, destId, name, ttl, data, events } = args;
    console.log(args)
    const relationshipId = await contracts.relationshipModule.getRelationshipId(name);
    console.log("Relationship id:", relationshipId)
    console.log("Creating Relationship...: ");
    const params = {
        sourceContract,
        sourceId,
        destContract,
        destId,
        relationshipId,
        ttl,
    }
    console.log(params)
    if (data !== '0x') {
        console.log("data: ", data);
    }
    const tx = await contracts.relationshipModule.relate(params, data)
    
    console.log("tx: ", tx.hash);
    console.log("Waiting for tx to be mined...");
    const receipt = await tx.wait();
    if (events) {
        console.log("Events: ");
        console.log(receipt.events);
    }
    console.log("Relationship created");
    
}

module.exports = main;
