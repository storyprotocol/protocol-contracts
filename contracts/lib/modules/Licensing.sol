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
        /// License status. // TODO: IPA status should follow
        LicenseStatus status;
        /// address granting the license
        address licensor;
        address licensee;
        /// address that could make a license invalid
        address revoker;
        /// address of the ip org that produced the terms
        address ipOrg;
        /// If the licensee is bound to an IPA, this is the IPA id. 0 otherwise
        uint256 ipaId;
        /// The id of the parent license. 0 if this this is tied to the first IPA of an IPOrg
        uint256 parentLicenseId;        
        ShortString frameworkId;
        ParamValue[] params;
    }

    struct LicenseStorage {
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
        ShortString frameworkId;
        mapping(ShortString => bytes) paramValues;
    }

    enum LicenseStatus {
        Unset,
        Active,
        Inactive,
        Revoked,
        Used
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
        /// Only Active or Pending will be accepted here
        LicenseStatus status;
        /// address granting the license
        address licensor;
        /// The address that will own the license NFT
        address licensee;
        /// address that could make a license invalid
        address revoker;
        /// address of the ip org that produced the terms
        address ipOrg;
        /// The id of the parent license. 0 if this this is tied to the first IPA of an IPOrg
        uint256 parentLicenseId;
        /// The ids of the Licensing Terms that make up the license.
        ParamValue[] params;
        /// If the licensee is bound to an IPA, this is the IPA id. 0 otherwise
        uint256 ipaId;
        /// Framework id
        ShortString frameworkId;
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
        LicensorConfig licensor;
    }

    enum LicensorConfig {
        Unset,
        IpOrgAlways,
        ParentLicenseeOrIPAOwner
    }
    
    uint256 constant MAX_PARAM_TAGS = 150;
    bytes32 constant USER_SETEABLE_CONFIG = keccak256("USER_SETEABLE_CONFIG");
    
    /// Input for IpOrg legal terms configuration in LicensingModule (for now, the only option)
    bytes32 constant LICENSING_FRAMEWORK_CONFIG = keccak256("LICENSING_FRAMEWORK_CONFIG");
    bytes32 constant CREATE_LICENSE = keccak256("CREATE_LICENSE");
    bytes32 constant ACTIVATE_LICENSE = keccak256("ACTIVATE_LICENSE");
    bytes32 constant LINK_LNFT_TO_IPA = keccak256("LINK_LNFT_TO_IPA");
}