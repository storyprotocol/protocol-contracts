const loadDeployment = require('./loadDeployment.js');
const { getIPAssetRegistryAddress } = require('./getIPAssetRegistryAddress.js');
const { createIPAsset, validateIPAssetType } = require('./createIPAsset.js');
const { readFileSync, writeFileSync } = require('fs');

////// ARRAYS //////

Array.range = function (n) {
    return Array(n)
        .fill()
        .map((_, i) => i);
};

Array.prototype.chunk = function (size) {
    return Array.range(Math.ceil(this.length / size)).map((i) => this.slice(i * size, i * size + size));
};

////// IP ASSETS //////

function getCreatedIpAssets(receipt, ipAssetRegistry) {
    if (receipt.events) {
        return events.filter((e) => e.event === "IPAssetWritten").map((e) => e.args);
    } else {
        const events = receipt.logs
        .filter(log => log.topics[0] === ipAssetRegistry.interface.getEventTopic("IPAssetWritten"))
        .map((log) => {
            return ipAssetRegistry.interface.parseLog(log);
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

const mapIpAssets = (jsonIpAssets, createdIpAssets) => {
    return jsonIpAssets.map((jIpa) => {
        const newIpa = createdIpAssets.find((cIpa) => cIpa.name === jIpa.name);
        if (newIpa) {
            console.log('Found!')
            return { ...jIpa, id: newIpa.id };
        } else {
            console.log('Not found...')
            return jIpa;
        }
    });
}

const ipAssetNumberToJSONKey = (ipAssetType) => {
    switch (ipAssetType) {
        case 1:
            return "stories";
        case 2:
            return "characters";
        case 3:
            return "art";
        case 4:
            return "groups";
        case 5:
            return "locations";
        case 6:
            return "items";
        default:
            throw new Error("Invalid story block type: " + ipAssetType);
    }
}


const updateFileData = (data, ipAssetType, createdIpAssets)  => {
    console.log(createdIpAssets)
    const assetsOfThisType = createdIpAssets.filter((ipAsset) => ipAsset.blockType === ipAssetType);
    console.log("assetsOfThisType: ", assetsOfThisType);
    const key = ipAssetNumberToJSONKey(ipAssetType);
    console.log("key: ", key);
    if (assetsOfThisType.length > 0) {
        data['ip-assets'][key] = mapIpAssets(data['ip-assets'][key], assetsOfThisType);

    }
}

async function updateIds(ethers, txHash, data, filePath, ipAssetRegistry) {
    const provider = ethers.provider;
    const receipt = await provider.getTransactionReceipt(txHash);

    const createdIpAssets = getCreatedIpAssets(receipt, ipAssetRegistry);
    console.log(createdIpAssets)

    updateFileData(data, 1, createdIpAssets);
    updateFileData(data, 2, createdIpAssets);
    updateFileData(data, 3, createdIpAssets);
    updateFileData(data, 4, createdIpAssets);
    updateFileData(data, 5, createdIpAssets);
    updateFileData(data, 6, createdIpAssets);
    
    writeFileSync(filePath, JSON.stringify(data, null, 2));
}

async function batchUploadIpAssets(data, contracts, ipRegistryAddress, receiver, batchSize, chainId, ethers, filePath) {
    const ipAssets = Object.keys(data['ip-assets'])
        .map((key) => data['ip-assets'][key])
        .reduce((acc, val) => acc.concat(val), [])
        .map((ipAsset) => { return { ...ipAsset, ipAssetType: validateIPAssetType(ipAsset.ipAssetType) }; })
        .filter((ipAsset) => ipAsset.id === null);

    console.log("Will upload: ", ipAssets.length, "story blocks");

    const ipAssetRegistry = await contracts.IPAssetsRegistry.attach(ipRegistryAddress);

    const calls = ipAssets.map((ipAsset) => {
        return ipAssetRegistry.interface.encodeFunctionData(
            'createIPAsset',
            [
                ipAsset.ipAssetType,
                ipAsset.name,
                ipAsset.description,
                ipAsset.mediaURL ?? '',
                receiver,
                0
            ]
        );
    });

    console.log('Batches: ', Math.ceil(calls.length / batchSize));

    await Promise.all(
        calls.chunk(batchSize).map(async (callChunk) => {
            console.log('Uploading batch of ', callChunk.length, ' story blocks');
            let tx;
            try {
                tx = await ipAssetRegistry.multicall(callChunk);
            } catch (e) {
                console.log('ERROR batchUploader');
                console.log('chainId', chainId);
                throw new Error(e);
            }
            console.log('tx: ', tx.hash);
            console.log('Waiting for tx to be mined...');
            const receipt = await tx.wait();
            return updateIds(ethers, tx.hash, data, filePath, ipAssetRegistry);
        })
    ).then(() => console.log('IpAssets created!'));
}

////// RELATIONSHIPS //////

async function batchUploadRelationships(data, contracts, ipaRegistryAddress, batchSize, chainId, ethers, filePath) {
    const relationshipModule = await contracts.protocolRelationshipModule;
    const relationshipParams = await Promise.all(data.relationships.map(
        async (relationship) => {
            const { sourceContract, destContract, ttl, name, sourceAssetType, sourceAssetIndex, destAssetType, destAssetIndex } = relationship;
            const sourceId = (data['ip-assets'])[sourceAssetType][sourceAssetIndex].id;
            const destId = (data['ip-assets'])[destAssetType][destAssetIndex].id;
            const relationshipId = await relationshipModule.getRelationshipId(name);
            const params = {
                sourceContract: sourceContract === "same" ? ipaRegistryAddress : sourceContract,
                sourceId,
                destContract: destContract === "same" ? ipaRegistryAddress : destContract,
                destId,
                relationshipId,
                ttl
            };
            return params;
        }
    ));

    console.log(relationshipParams)
    
    console.log("Uploading " + relationshipParams.length + " relationships...");
    const relCalls = relationshipParams.map(
        (relationship) => {
            return relationshipModule.interface.encodeFunctionData('relate', [relationship, "0x"]);
        }
    );

    await Promise.all(
        relCalls.chunk(batchSize).map(async (callChunk) => {
            console.log('Uploading batch of ', callChunk.length, ' relationships');
            let tx;
            try {
                tx = await relationshipModule.multicall(callChunk);
            } catch (e) {
                console.log('ERROR batchUploader');
                console.log('chainId', chainId);
                throw new Error(e);
            }
            console.log('tx: ', tx.hash);
            console.log('Waiting for tx to be mined...');
            const receipt = await tx.wait();
            return updateRelationships(receipt, data, filePath, relationshipModule);
        })
    ).then(() => console.log('Relationships created!'));
}

async function updateRelationships(receipt, data, filePath, relationshipModule) {
    let createdRelationships;

    if (receipt.events) {
        createdRelationships = receipt.events.filter((e) => e.event === "RelationSet").map((e) => e.args);
    } else {
        createdRelationships = receipt.logs.map((log) => {
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
        data.relationships[index] = {
            ...relationship,
            sourceId: createdRelationship.sourceId.toNumber(),
            destId: createdRelationship.destId.toNumber(),
            relationshipId: createdRelationship.relationshipId
        }
    })

    writeFileSync(filePath, JSON.stringify(data, null, 2));
}

////// EXPORTED METHODS //////

async function main(args, hre) {
    const { ethers } = hre;
    const { chainId, contracts } = await loadDeployment(hre);
    const { franchiseId, receiver, filePath, batchSize } = args;
    const data = JSON.parse(readFileSync(filePath, 'utf8'));
    const { address } = await getIPAssetRegistryAddress(ethers, franchiseId, contracts);

    await batchUploadIpAssets(data, contracts, address, receiver, batchSize, chainId, ethers, filePath);

    console.log('Setting up relationships...')

    await batchUploadRelationships(data, contracts, address, batchSize, chainId, ethers, filePath);
}

async function updateIdsTask(args, hre) {
    const { ethers } = hre;
    const { franchiseId, tx, filePath } = args;
    const data = JSON.parse(readFileSync(filePath, 'utf8'));
    const { chainId, contracts } = await loadDeployment(hre);
    const { address } = await getIPAssetRegistryAddress(ethers, franchiseId, contracts);
    const ipAssetRegistry = await contracts.IPAssetsRegistry.attach(address);
    await updateIds(ethers, tx, data, filePath, ipAssetRegistry);
}

module.exports = main;
module.exports.updateIds = updateIdsTask;
