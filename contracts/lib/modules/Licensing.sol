// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { ShortString } from "@openzeppelin/contracts/utils/ShortStrings.sol";
import { IHook } from "contracts/interfaces/hooks/base/IHook.sol";
import { FixedSet } from "contracts/utils/FixedSet.sol";

library Licensing {

    struct License {
        bool isCommercial;
        address licensor;
        address revoker;
        address ipOrg;
        LicenseeType licenseeType;
        uint256 ipaId;
        uint256 parentLicenseId;
        ShortString[] termIds;
        bytes[] termsData;
        bytes data;
    }

    struct LicenseCreation {
        bool isCommercial;
        uint256 parentLicenseId;
        // TODO: How do we do per user configured terms?
        // ShortString[] extraTermIds;
        // bytes[] extraTermsData;
    }

    struct RegistryAddition {
        bool isCommercial;
        address licensor;
        address revoker;
        address ipOrg;
        uint256 parentLicenseId;
        ShortString[] termIds;
        bytes[] termsData;
        bytes data;
    }
    
    enum LicenseeType {
        Unset,
        BoundToIpa,
        LNFTHolder
    }

    enum CommercialStatus {
        Unset,
        Commercial,
        NonCommercial,
        Both
    }

    struct LicensingTerm {
        CommercialStatus comStatus;
        string url;
        string hash;
        string algorithm;
        IHook hook;
        // ITermDecoder decoder; // TODO: some terms just need to decode bytes data, not
        // a full blown hook
    }

    // NOTE: we cannot use this in structs that are going to be saved
    // to storage, like License
    struct TermsConfig {
        ShortString[] termIds;
        bytes[] termData;
    }

    struct FrameworkConfig {
        TermsConfig comTermsConfig;
        TermsConfig nonComTermsConfig;
    }
    
    bytes32 constant LICENSING_FRAMEWORK_CONFIG = keccak256("LICENSING_FRAMEWORK_CONFIG");
}