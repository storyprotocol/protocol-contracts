// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IHook } from "contracts/interfaces/hooks/base/IHook.sol";
import { FixedSet } from "contracts/utils/FixedSet.sol";
import { ShortString } from "@openzeppelin/contracts/utils/ShortStrings.sol";

/// @title Licensing Module Library
/// Structs needed by the Licensing Modules and registries
library Licensing {
    enum LicenseStatus {
        Unset,
        Active,
        PendingLicensorApproval,
        Revoked
    }

    enum ParameterType {
        Bool,
        Number,
        Address,
        String,
        MultipleChoice // ShortString set
    }

    enum LicensorConfig {
        Unset,
        IpOrgOwnerAlways,
        ParentOrIpaOrIpOrgOwners
    }

    struct LicenseData {
        /// License status. // TODO: IPA status should follow
        LicenseStatus status;
        bool isReciprocal;
        bool derivativeNeedsApproval;
        address revoker;
        /// address granting the license
        address licensor;
        /// address of the ip org that produced the terms
        address ipOrg;
        ShortString frameworkId;
        /// If the licensee is bound to an IPA, this is the IPA id. 0 otherwise
        uint256 ipaId;
        /// The id of the parent license. 0 if this this is tied to the first IPA of an IPOrg
        uint256 parentLicenseId;
    }

    struct LicenseCreation {
        ParamValue[] params;
        uint256 parentLicenseId;
        uint256 ipaId;
    }

    struct ParamDefinition {
        ShortString tag;
        ParameterType paramType;
    }

    struct ParamValue {
        ShortString tag;
        bytes value;
    }

    struct FrameworkStorage {
        string textUrl;
        FixedSet.ShortStringSet paramTags;
        mapping(ShortString => ParameterType) paramTypes;
        ParamDefinition[] paramDefs;
    }

    struct SetFramework {
        string id;
        string textUrl;
        ParamDefinition[] paramDefs;
    }

    struct LicensingConfig {
        string frameworkId;
        ParamValue[] params;
        LicensorConfig licensor;
    }

    uint256 constant MAX_PARAM_TAGS = 150;

    /// Input for IpOrg legal terms configuration in LicensingModule (for now, the only option)
    bytes32 constant LICENSING_FRAMEWORK_CONFIG =
        keccak256("LICENSING_FRAMEWORK_CONFIG");
    bytes32 constant CREATE_LICENSE = keccak256("CREATE_LICENSE");
    bytes32 constant ACTIVATE_LICENSE = keccak256("ACTIVATE_LICENSE");
    bytes32 constant LINK_LNFT_TO_IPA = keccak256("LINK_LNFT_TO_IPA");
    address constant ALPHA_REVOKER = 0x130c1977A3C73Db51DE55B705A1D924aA78467c5;

    function _statusToString(
        LicenseStatus status_
    ) internal pure returns (string memory) {
        if (status_ == LicenseStatus.Unset) {
            return "Unset";
        } else if (status_ == LicenseStatus.Active) {
            return "Active";
        } else if (status_ == LicenseStatus.PendingLicensorApproval) {
            return "Pending Licensor Approval";
        } else if (status_ == LicenseStatus.Revoked) {
            return "Revoked";
        }
        return "Unknown";
    }

    function _validateParamValue(
        Licensing.ParameterType pType,
        bytes memory value
    ) internal pure returns (bool) {
        // An empty value signals the parameter is untagged, to trigger default values in the
        // license agreement text, but that's valid
        if (keccak256(value) == keccak256("")) {
            return true;
        }
        if (pType == Licensing.ParameterType.Bool) {
            abi.decode(value, (bool));
            return true;
        } else if (pType == Licensing.ParameterType.Number) {
            if (abi.decode(value, (uint256)) == 0) {
                return false;
            }
        } else if (pType == Licensing.ParameterType.Address) {
            // Not supporting address(0) as a valid value
            if (abi.decode(value, (address)) == address(0)) {
                return false;
            }
        } else if (pType == Licensing.ParameterType.String) {
            abi.decode(value, (string));
            // WARNING: Do proper string validation off chain.
            if (
                keccak256(value) == keccak256(abi.encode(" ")) ||
                keccak256(value) == keccak256(abi.encode(""))
            ) {
                return false;
            }
        } else if (pType == Licensing.ParameterType.MultipleChoice) {
            ShortString[] memory s = abi.decode(value, (ShortString[]));
            // No choice is not a valid value, if you need this have a value called
            // "None" or something
            if (s.length == 0) {
                return false;
            }
        }
        return true;
    }

}
