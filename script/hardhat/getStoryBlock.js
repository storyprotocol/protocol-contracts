const loadDeployment = require('./loadDeployment.js');
const { getStoryBlockRegistryAddress } = require('./getStoryBlockRegistryAddress.js');


async function main(args, hre) {
    const { ethers } = hre;
    const { chainId, contracts } = await loadDeployment(hre);
    const { franchiseId, storyBlockId } = args;
    const { address } = await getStoryBlockRegistryAddress(ethers, franchiseId, contracts);
    
    const storyBlockRegistry = await contracts.StoryBlocksRegistry.attach(address);
    const sb = await storyBlockRegistry.callStatic.readStoryBlock(storyBlockId);
    console.log(sb);
    return sb;
}

module.exports = main;
