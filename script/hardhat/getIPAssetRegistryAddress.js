const loadDeployment = require('./loadDeployment.js');

async function getIPAssetRegistryAddress(ethers, franchiseId, contracts) {
    console.log("Getting story block registry for franchise id: ", franchiseId);

    const address = await contracts.franchiseRegistry.callStatic.IPAssetRegistryForId(franchiseId)
    if (address === ethers.constants.AddressZero) {
        throw new Error("Story block registry not found for franchise id: " + franchiseId);
    }
    console.log("Address: ", address);
    return { address };
}

async function main(args, hre) {
    const { ethers } = hre;
    const { contracts } = await loadDeployment(hre);

    const { franchiseId } = args;
    return await getIPAssetRegistryAddress(ethers, franchiseId, contracts);
}

module.exports = main;
module.exports.getIPAssetRegistryAddress = getIPAssetRegistryAddress;
