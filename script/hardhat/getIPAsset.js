const loadDeployment = require('./loadDeployment.js');
const { getIPAssetRegistryAddress } = require('./getIPAssetRegistryAddress.js');


async function main(args, hre) {
    const { ethers } = hre;
    const { chainId, contracts } = await loadDeployment(hre);
    const { franchiseId, IPAssetId } = args;
    const { address } = await getIPAssetRegistryAddress(ethers, franchiseId, contracts);
    
    const IPAssetRegistry = await contracts.IPAssetsRegistry.attach(address);
    const sb = await IPAssetRegistry.callStatic.readIPAsset(IPAssetId);
    console.log(sb);
    return sb;
}

module.exports = main;
