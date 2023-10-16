// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { ITermsProcessor } from "contracts/interfaces/modules/licensing/terms/ITermsProcessor.sol";

/// @title Licensing Module Library
library Licensing {

    /// @notice Configuration for terms processing.
    struct TermsProcessorConfig {
        ITermsProcessor processor;
        bytes data;
    }

    /// @notice IP asset configuration for IP licensing.
    struct IpAssetConfig {
        bool canSublicense; // If false, this IPAsset cannot be parentLicenseId of any other IPAsset
        uint256 franchiseRootLicenseId; // If set, root IPAsset licenses will have this as their parentLicenseId
        // TODO: allowed license terms? processors?
        // TODO: limit medium of sublicenses? As in, you can only license prose to prose? something like LibIPAssetMask?
        // TODO: limit who you can sublicense to?
    }

    /// @notice Franchise configuration for IP licensing.
    struct FranchiseConfig {
        IpAssetConfig nonCommercialConfig;
        TermsProcessorConfig nonCommercialTerms;
        IpAssetConfig commercialConfig;
        TermsProcessorConfig commercialTerms;
        bool rootIpAssetHasCommercialRights;
        address revoker;
        string commercialLicenseUri;
    }


    /// @notice Core licensing structure.
    struct License {
        bool active;
        bool canSublicense;
        bool commercial;
        uint256 parentLicenseId;
        uint256 tokenId;
        address revoker;
        string uri; // NOTE: should we merge this with IPAssetRegistry tokenURI for Licenses who are rights?
        ITermsProcessor termsProcessor;
        bytes termsData;
    }

}
