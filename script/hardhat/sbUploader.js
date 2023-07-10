const loadDeployment = require('./loadDeployment.js');
const { getIPAssetRegistryAddress } = require('./getIPAssetRegistryAddress.js');
const { createIPAsset, validateIPAssetType } = require('./createIPAsset.js');
const { readFileSync, writeFileSync } = require('fs');

Array.range = function (n) {
    return Array(n)
        .fill()
        .map((_, i) => i);
};

Array.prototype.chunk = function (size) {
    return Array.range(Math.ceil(this.length / size)).map((i) => this.slice(i * size, i * size + size));
};

function getCreatedBlocks(receipt, IPAssetRegistry) {
    if (receipt.events) {
        return events.filter((e) => e.event === "IPAssetWritten").map((e) => e.args);
    } else {
        const events = receipt.logs.map((log) => {
            return IPAssetRegistry.interface.parseLog(log);
        }).filter((e) => e.name === "IPAssetWritten")
        .map((e) => {
            const ev = Object.keys(e.args).reduce((acc, key) => {
                acc[key] = e.args[key];
                return acc;
            }, {});
            return ev;
        })
        .map((e) => {
            e.id = e.IPAssetId.toNumber();
            return e;
        });
        return events;
    }
}

async function updateIds(ethers, txHash, data, filePath, IPAssetRegistry) {
    const provider = ethers.provider;
    const receipt = await provider.getTransactionReceipt(txHash);

    const createdBlocks = getCreatedBlocks(receipt, IPAssetRegistry);

    const mapBlocks = (blocks, createdBlocks) => {
        return blocks.map((b) => {
            const createdBlock = createdBlocks.find((s) => s.name === b.name);
            if (createdBlock) {
                return { ...b, id: createdBlock.id };
            } else {
                return b;
            }
        });
    }
    const createdStories = createdBlocks.filter((block) => block.blockType === 1);
    if (createdStories.length > 0) {
        data.blocks.stories = mapBlocks(data.blocks.stories, createdStories);
    }
    const createdCharacters = createdBlocks.filter((block) => block.blockType === 2);
    if (createdCharacters.length > 0) {
        data.blocks.characters = mapBlocks(data.blocks.characters, createdCharacters);
    }
    const createdArts = createdBlocks.filter((block) => block.blockType === 3);
    if (createdArts.length > 0) {
        data.blocks.arts = mapBlocks(data.blocks.arts, createdArts);
    }
    const createdGroups = createdBlocks.filter((block) => block.blockType === 4);
    if (createdGroups.length > 0) {
        data.blocks.groups = mapBlocks(data.blocks.groups, createdGroups);
    }
    const createdLocations = createdBlocks.filter((block) => block.blockType === 5);
    if (createdLocations.length > 0) {
        data.blocks.locations = mapBlocks(data.blocks.locations, createdLocations);
    }
    const createdItems = createdBlocks.filter((block) => block.blockType === 6);
    if (createdItems.length > 0) {
        data.blocks.items = mapBlocks(data.blocks.items, createdItems);
    }
    writeFileSync(filePath, JSON.stringify(data, null, 2));
}
    


async function main(args, hre) {
    const { ethers } = hre;
    const { chainId, contracts } = await loadDeployment(hre);
    const { franchiseId, filePath, batchSize  } = args;
    const data = JSON.parse(readFileSync(filePath, 'utf8'));
    const { address } = await getIPAssetRegistryAddress(ethers, franchiseId, contracts);

    const blocks = Object.keys(data.blocks)
        .map((key) => data.blocks[key])
        .reduce((acc, val) => acc.concat(val), [])
        .map((block) => { return { ...block, numBlockType: validateIPAssetType(block.blockType) }})
        .filter((block) => block.id === null);
    console.log("Will upload: ", blocks.length, "story blocks");

    const IPAssetRegistry = await contracts.IPAssetsRegistry.attach(address);
    const calls = blocks.map((block) => {
        return IPAssetRegistry.interface.encodeFunctionData('createIPAsset', [block.numBlockType, block.name, block.description, block.mediaURL ?? ''])
    });

    console.log('Batches: ', Math.ceil(calls.length / batchSize));
    
    await Promise.all(
        calls.chunk(batchSize).map(async (callChunk) => {
            console.log('Uploading batch of ', callChunk.length, ' story blocks');
            let tx;
            try {
                tx = await IPAssetRegistry.multicall(callChunk);
            } catch (e) {
                console.log('ERROR sbUploader');
                console.log('chainId', chainId);
                throw new Error(e);
            }
            console.log('tx: ', tx.hash);
            console.log('Waiting for tx to be mined...');
            const receipt = await tx.wait();
            return updateIds(ethers, tx.hash, data, filePath, IPAssetRegistry);
        })
    ).then(() => console.log('Blocks created!'));

}

async function updateIdsTask(args, hre) {
    const { ethers } = hre;
    const { franchiseId, tx, filePath } = args;
    const data = JSON.parse(readFileSync(filePath, 'utf8'));
    const { chainId, contracts } = await loadDeployment(hre);
    const { address } = await getIPAssetRegistryAddress(ethers, franchiseId, contracts);
    const IPAssetRegistry = await contracts.IPAssetsRegistry.attach(address);
    await updateIds(ethers, tx, data, filePath, IPAssetRegistry);
}


module.exports = main;
module.exports.updateIds = updateIdsTask;
