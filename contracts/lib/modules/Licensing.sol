// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IHook } from "contracts/interfaces/hooks/base/IHook.sol";
import { FixedSet } from "contracts/utils/FixedSet.sol";
import { ShortString } from "@openzeppelin/contracts/utils/ShortStrings.sol";

/// @title Licensing Module Library
/// Structs needed by the Licensing Modules and registries
library Licensing {

    /// @notice Struct that holds the data for a license
    struct License {
        /// States the commercial nature of the license. All terms will follow.
        bool isCommercial;
        /// License status. // TODO: IPA status should follow
        LicenseStatus status;
        /// address granting the license
        address licensor;
        /// address that could make a license invalid
        address revoker;
        /// address of the ip org that produced the terms
        address ipOrg;
        /// If the licensee is bound to an IPA, this is the IPA id. 0 otherwise
        uint256 ipaId;
        /// The id of the parent license. 0 if this this is tied to the first IPA of an IPOrg
        uint256 parentLicenseId;
        /// The ids of the Licensing Terms that make up the license.
        /// The terms definitions are in TermsRepository contract
        ShortString[] termIds;
        /// The data configuring each term. May be empty bytes. May be passed to the term hook
        bytes[] termsData;
    }

    enum LicenseStatus {
        Unset,
        Active,
        Revoked,
        Pending
    }

    /// User facing parameters for creating a license
    struct LicenseCreation {
        bool isCommercial;
        uint256 parentLicenseId;
        // TODO: How do we do per user configured terms?
        // ShortString[] extraTermIds;
        // bytes[] extraTermsData;
    }

    /// Input to add a License the LicenseRegistry 
    struct RegistryAddition {
        /// States the commercial nature of the license. All terms will follow.
        bool isCommercial;
        /// Only Active or Pending will be accepted here
        LicenseStatus status;
        /// address granting the license
        address licensor;
        /// address that could make a license invalid
        address revoker;
        /// address of the ip org that produced the terms
        address ipOrg;
        /// The id of the parent license. 0 if this this is tied to the first IPA of an IPOrg
        uint256 parentLicenseId;
        /// The ids of the Licensing Terms that make up the license.
        ShortString[] termIds;
        /// The data configuring each term. May be empty bytes. May be passed to the term hook
        bytes[] termsData;
    }
    

    enum ParameterType {
        Bool,
        Number,
        Address,
        String,
        MultipleChoice // ShortString set, meanings provided by the framework
    }

    struct FrameworkStorage {
        string textUrl;
        FixedSet.ShortStringSet paramTags;
        mapping(ShortString => ParameterType) paramTypes;
    }

    struct SetFramework {
        string id;
        string textUrl;
        ParamDefinition[] paramDefs;
    }

    struct ParamDefinition {
        ShortString tag;
        ParameterType paramType;
    }

    struct ParamValue {
        ShortString tag;
        bytes value;
    }
    
    struct LicensingConfig {
        string frameworkId;
        ParamValue[] params;
    }
    
    uint256 constant MAX_PARAM_TAGS = 150;
    
    /// Input for IpOrg legal terms configuration in LicensingModule (for now, the only option)
    bytes32 constant LICENSING_FRAMEWORK_CONFIG = keccak256("LICENSING_FRAMEWORK_CONFIG");
    bytes32 constant CREATE_LICENSE = keccak256("CREATE_LICENSE");
    bytes32 constant ACTIVATE_LICENSE = keccak256("ACTIVATE_LICENSE");
    bytes32 constant BOND_LNFT_TO_IPA = keccak256("BOND_LNFT_TO_IPA");
}