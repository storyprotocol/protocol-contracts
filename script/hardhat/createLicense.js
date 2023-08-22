const loadDeployment = require('./loadDeployment.js');
const { getIPAssetRegistryAddress } = require('./getIPAssetRegistryAddress.js');

function findId(events) {
    const event = events.find((e) => e.event === "Transfer");
    return event.args.tokenId.toString()
}



async function main(args, hre) {
    const { ethers } = hre;
    const { chainId, contracts } = await loadDeployment(hre);
    const { franchiseId, ipAssetId, commercial, licenseURI, imageURI, usage, duration, rights, name, events } = args;
    console.log(args)
    const franchiseRegistry = contracts.franchiseRegistry;
    console.log("Creating license...: ");

    const tx = await franchiseRegistry.createLicense(
        franchiseId,
        ipAssetId,
        commercial,
        ethers.utils.id(name, franchiseId, ipAssetId),
        licenseURI,
        {
            imageURI,
            usage,
            duration,
            rights,
            name,
        }
    )
    
    console.log("tx: ", tx.hash);
    console.log("Waiting for tx to be mined...");
    const receipt = await tx.wait();
    if (events) {
        console.log("Events: ");
        console.log(receipt.events);
    }
    const id = findId(receipt.events);
    console.log("License created: ", id);
    
    return { id };
}

module.exports = main;
