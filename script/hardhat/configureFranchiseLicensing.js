const loadDeployment = require('./loadDeployment.js');
const { getContractAddress } = require('@ethersproject/address');

function findId(events) {
    const event = events.find((e) => e.event === "FranchiseConfigSet");
    return {
        id: event.args.id.toString(),
    };
}

async function main(args, hre) {
    const { ethers } = hre;
    const { chainId, contracts } = await loadDeployment(hre);
    const {
        franchiseId,
        nonCommercialCanSublicense,
        nonCommercialRootLicenseId,
        commercialCanSublicense,
        commercialRootLicenseId,
        rootIpAssetHasCommercialRights,
        revoker,
        commercialLicenseUri,
        events,
    } = args;
    console.log("Configuring licensing for franchise: ", franchiseId);
    
    /**
    struct IpAssetConfig {
        bool canSublicense; // If false, this IPAsset cannot be parentLicenseId of any other IPAsset
        uint256 franchiseRootLicenseId; // If set, root IPAsset licenses will have this as their parentLicenseId
        // TODO: allowed license terms? processors?
        // TODO: limit medium of sublicenses? As in, you can only license prose to prose? something like LibIPAssetMask?
        // TODO: limit who you can sublicense to?
    }

    struct FranchiseConfig {
        IpAssetConfig nonCommercialConfig;
        IERC5218.TermsProcessorConfig nonCommercialTerms;
        IpAssetConfig commercialConfig;
        IERC5218.TermsProcessorConfig commercialTerms;
        bool rootIpAssetHasCommercialRights;
        address revoker;
        string commercialLicenseUri;
        
    }*/
    const params = {
        nonCommercialConfig: {
            canSublicense: nonCommercialCanSublicense == 'true',
            franchiseRootLicenseId: nonCommercialRootLicenseId,
        },
        nonCommercialTerms: {
            processor: ethers.constants.AddressZero,
            processorData: [],
        },
        commercialConfig: {
            canSublicense: commercialCanSublicense == 'true',
            franchiseRootLicenseId: commercialRootLicenseId
        },
        commercialTerms: {
            processor: ethers.constants.AddressZero,
            processorData: [],
        },
        rootIpAssetHasCommercialRights: rootIpAssetHasCommercialRights == 'true',
        revoker: revoker,
        commercialLicenseUri: commercialLicenseUri,
    };
    console.log(params)
    const tx = await contracts.licensingModule.configureFranchiseLicensing(
        franchiseId,
        params
    );
    console.log("Franchise created in tx: ", tx.hash);
    console.log("Waiting for tx to be mined...");
    const receipt = await tx.wait();
    if (events) {
        console.log("Events: ");
        console.log(receipt.events);
    }
    console.log("FranchiseConfigSet");
    const { id } = findId(receipt.events);
    console.log("id: ", id);
    return { id };
}

module.exports = main;
