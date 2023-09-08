const loadDeployment = require('./loadDeployment.js');
const { getIPAssetRegistryAddress } = require('./getIPAssetRegistryAddress.js');
const { createIPAsset, validateIPAssetType } = require('./createIPAsset.js');
const { readFileSync, writeFileSync } = require('fs');

const ASSET_CREATED_TOPIC = "0x9081eaced0c09521965c689337c0d5ed61a0baeb8b9f0fda7a4cd4f59a251515"
const LICENSE_GRANTED_TOPIC = "0xc4c430c7298394a4f1268e65ccf943343f533fb611f496755716d2548b074cad"

Array.range = function (n) {
    return Array(n)
        .fill()
        .map((_, i) => i);
};

Array.prototype.chunk = function (size) {
    return Array.range(Math.ceil(this.length / size)).map((i) => this.slice(i * size, i * size + size));
};

async function getCreatedBlocks(receipt, IPAssetRegistry, IPAssetEventEmitter, LicensingModule) {
    if (receipt.events) {
        return events.filter((e) => e.event === "IPAssetWritten").map((e) => e.args);
    } else {
        const events = receipt.logs.map( (log) => {
            if (log.topics[0] == ASSET_CREATED_TOPIC) {
                return IPAssetEventEmitter.interface.parseLog(log);
            } else if (log.topics[0] == LICENSE_GRANTED_TOPIC) {
                return LicensingModule.interface.parseLog(log);
            } else {
                return IPAssetRegistry.interface.parseLog(log);
            }
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

async function updateIds(ethers, txHash, data, filePath, IPAssetRegistry, IPAssetEventEmitter, LicensingModule) {
    const provider = ethers.provider;
    const receipt = await provider.getTransactionReceipt(txHash);

    const createdBlocks = await getCreatedBlocks(receipt, IPAssetRegistry, IPAssetEventEmitter, LicensingModule);
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

    const { FranchiseRegistry, franchiseRegistry, IPAssetsRegistry, IPAssetEventEmitter, LicensingModule, ProtocolRelationshipModule, relationshipModule } = contracts;
    const calls = blocks.map((block) => {
        return FranchiseRegistry.interface.encodeFunctionData('createIPAsset', [franchiseId, block.numBlockType, block.name, block.description, block.mediaURL ?? ''])
    });

    console.log('Batches: ', Math.ceil(calls.length / batchSize));
    
    await Promise.all(
        calls.chunk(batchSize).map(async (callChunk) => {
            console.log('Uploading batch of ', callChunk.length, ' story blocks');
            let tx;
            try {
                tx = await franchiseRegistry.multicall(callChunk);
            } catch (e) {
                console.log('ERROR sbUploader');
                console.log('chainId', chainId);
                throw new Error(e);
            }
            console.log('tx: ', tx.hash);
            console.log('Waiting for tx to be mined...');
            const receipt = await tx.wait();
            // function call is getting rather long, would it be more efficient to pass contracts itself?
            return updateIds(ethers, tx.hash, data, filePath, IPAssetsRegistry, IPAssetEventEmitter, LicensingModule);
        })
    ).then(() => console.log('Blocks created!'));

    console.log('Setting up relationships...')

    const relationshipParams = await Promise.all(data.relationships.map(
        async (relationship) => {
            const { sourceContract, destContract, ttl, name, sourceAssetType, sourceAssetIndex, destAssetType, destAssetIndex } = relationship
            const sourceId = (data.blocks)[sourceAssetType][sourceAssetIndex].id
            const destId = (data.blocks)[destAssetType][destAssetIndex].id
            const relationshipId = await relationshipModule.getRelationshipId(name);
            const params = {
                sourceContract,
                sourceId,
                destContract,
                destId,
                relationshipId,
                ttl
            }
            return params;
        }
    ))

    console.log("Uploading " + relationshipParams.length + " relationships...")
    const relCalls = relationshipParams.map(
        (relationship) => {
            return relationshipModule.interface.encodeFunctionData('relate', [relationship, "0x"])
        }
    )

    await Promise.all(
        relCalls.chunk(batchSize).map(async (callChunk) => {
            console.log('Uploading batch of ', callChunk.length, ' relationships');
            let tx;
            try {
                tx = await relationshipModule.multicall(callChunk);
            } catch (e) {
                console.log('ERROR sbUploader');
                console.log('chainId', chainId);
                throw new Error(e);
            }
            console.log('tx: ', tx.hash);
            console.log('Waiting for tx to be mined...');
            const receipt = await tx.wait();
            return updateRelationships(ethers, tx.hash, data, filePath, relationshipModule);
        })
    ).then(() => console.log('Relationships created!'));
}

async function updateRelationships(ethers, txHash, data, filePath, relationshipModule) {
    const provider = ethers.provider;
    const receipt = await provider.getTransactionReceipt(txHash);

    let createdRelationships;

    if (receipt.events) {
        createdRelationships = events.filter((e) => e.event === "RelationSet").map((e) => e.args);
    } else {
        createdRelationships = receipt.logs.map( (log) => {
            return relationshipModule.interface.parseLog(log)
        }).map((e) => {
            const ev = Object.keys(e.args).reduce((acc, key) => {
                acc[key] = e.args[key];
                return acc;
            }, {});
            return ev;
        })
    }
    
    console.log("Writing relationship information to file...")
    data.relationships.forEach((relationship, index) => {
        const createdRelationship = createdRelationships[index]
        data.relationships[index] = { ...relationship, 
            sourceId: createdRelationship.sourceId.toNumber(), 
            destId: createdRelationship.destId.toNumber(),
            relationshipId: createdRelationship.relationshipId }
    })

    writeFileSync(filePath, JSON.stringify(data, null, 2));
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
