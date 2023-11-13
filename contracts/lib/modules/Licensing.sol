// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { OffChain } from "contracts/lib/OffChain.sol";
import { ShortString } from "@openzeppelin/contracts/utils/ShortStrings.sol";
import { IHook } from "contracts/interfaces/hooks/base/IHook.sol";
import { FixedSet } from "contracts/utils/FixedSet.sol";

library Licensing {
    struct License {
        bool isCommercial;
        LicenseeType licenseeType;
        address licensor;
        address revoker;
        ShortString[] termIds;
        bytes[] termsData;
    }

    struct LicenseCreationParams {
        uint256 parentLicenseId;
        bool isCommercial;
        uint256 ipaId;
        // Intent intent;
    }

    enum LicenseeType {
        Unset,
        BoundToIpa,
        LNFTHolder
    }

    enum Intent {
        RootIpa, // No parent license
        DerivativeIpa,// Parent license id needed, will become untradeable after completion
        OffchainDerivative // Parent license id needed, need to log back
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
        ShortString[] termIds;
        bytes[] termData;
    }

    struct FrameworkConfig {
        TermsConfig comTermsConfig;
        TermsConfig nonComTermsConfig;
    }
    
    bytes32 constant LICENSING_FRAMEWORK_CONFIG = keccak256("LICENSING_FRAMEWORK_CONFIG");
}