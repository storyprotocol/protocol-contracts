// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { OffChain } from "contracts/lib/OffChain.sol";
import { ShortString } from "@openzeppelin/contracts/utils/ShortStrings.sol";
import { IHook } from "contracts/interfaces/hooks/base/IHook.sol";

library Licensing {
    
    struct License {
        bool isCommercial;
        bytes[] terms;
        address[] activationHooks;
        bytes[] activationHookParams;
    }

    enum CommercialStatus {
        Unset,
        Commercial,
        NonCommercial,
        Both
    }

    struct LicensingTerm {
        CommercialStatus comStatus;
        OffChain.Content text;
        IHook hook;
    }

    struct TermsConfig {
        ShortString termsId;
        bytes data;
    }

    struct FrameworkConfig {
        bool isCommercialAllowed;
        TermsConfig[] termsConfig;
    }

    // Available categories -> IPORg wide
    // Excluded categories (IPORg wide? IPA wide?)
    // Pure text terms
    // Share alike == sublicensing on/off
    // 
    // Attribution should point to a relationship Type
    bytes32 constant LICENSING_FRAMEWORK_CONFIG = keccak256("LICENSING_FRAMEWORK_CONFIG");
}

library TermCategories {
    string constant FORMAT_CATEGORIES = "FORMAT_CATEGORIES";
}

/// @dev must be < 32 bytes long, or they will blow up at some point
/// see https://docs.openzeppelin.com/contracts/4.x/api/utils#ShortStrings
library TermIds {
    string constant SHARE_ALIKE = "SHARE_ALIKE";
}
