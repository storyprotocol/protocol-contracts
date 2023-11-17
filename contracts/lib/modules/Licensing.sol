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
        /// Defines how to find the address of the licensee
        LicenseeType licenseeType;
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

    enum LicenseeType {
        // Empty value
        Unset,
        // The licensee is the owner of the IPA
        BoundToIpa,
        // The licensee is the owner of the NFT. ipaId will be 0 in the license
        LNFTHolder
    }

    /// Defines commercial status on a licensing term
    enum CommercialStatus {
        /// Empty value
        Unset,
        /// Term can only be used for commercial licenses
        Commercial,
        /// Term can only be used for non commercial licenses
        NonCommercial,
        /// Term could be used for both commercial and non commercial licenses
        Both
    }

    /// Data needed to create a Licensing Term. A collection of terms can be used to render
    /// a license text
    struct LicensingTerm {
        /// Defines commercial status on a licensing term
        CommercialStatus comStatus;
        /// URL where the term text can be found. If the destination is not available of changes
        /// Licenses created with this term will be candidates for revocation
        string url;
        /// Hash of the license text
        string hash;
        /// Hashing algorithm used
        string algorithm;
        /// If the Licensing term is enforceable on chain, this is the hook that will be called
        IHook hook;
        // Some terms just need to decode bytes data, not a full blown hook.
        // ITermDecoder decoder; // TODO: For now the LicensingModule knows how to decode the data per term id
    }

    /// Defines a collection of termIds and their config data. Must be same length
    /// @dev: we cannot use this in structs that are going to be saved
    /// to storage, like License
    struct TermsConfig {
        ShortString[] termIds;
        bytes[] termData;
    }

    /// Input for IpOrg legal terms configuration in LicensingModule
    struct FrameworkConfig {
        TermsConfig comTermsConfig;
        TermsConfig nonComTermsConfig;
    }
    
    /// Input for IpOrg legal terms configuration in LicensingModule (for now, the only option)
    bytes32 constant LICENSING_FRAMEWORK_CONFIG = keccak256("LICENSING_FRAMEWORK_CONFIG");
    bytes32 constant CREATE_LICENSE = keccak256("CREATE_LICENSE");
    bytes32 constant ACTIVATE_LICENSE = keccak256("ACTIVATE_LICENSE");
    bytes32 constant BOUND_LNFT_TO_IPA = keccak256("BOUND_LNFT_TO_IPA");
}