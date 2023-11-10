// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { OffChain } from "contracts/lib/OffChain.sol";
import { ShortString } from "@openzeppelin/contracts/utils/ShortStrings.sol";

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
        address encoder;
    }

    struct FrameworkConfig {
        bool isCommercialAllowed;
        ShortString[] termIds;
        bytes[] termConfigs;
    }

    // Available categories -> IPORg wide
    // Excluded categories (IPORg wide? IPA wide?)
    // Pure text terms
    // Share alike == sublicensing on/off
    // 
    // Attribution should point to a relationship Type

    
    bytes32 constant LICENSING_FRAMEWORK_CONFIG = keccak256("LICENSING_FRAMEWORK_CONFIG");

}