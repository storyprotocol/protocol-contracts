// SPDX-License-Identifier: UNLICENSED
// See https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.19;

import { FixedSet } from "contracts/utils/FixedSet.sol";
import { BitMask } from "contracts/lib/BitMask.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ShortStrings, ShortString } from "@openzeppelin/contracts/utils/ShortStrings.sol";

/// @title Licensing Module Library
/// Structs needed by the Licensing Modules and registries
library Licensing {
    using ShortStrings for *;
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
        ShortStringArray,
        // uint256 bitmask representing indexes in choices array. ParamDefinition will have the available choices array.
        MultipleChoice
    }

    enum LicensorConfig {
        Unset,
        IpOrgOwnerAlways,
        Source
    }

    struct LicenseData {
        /// License status. // TODO: IPA status should follow
        LicenseStatus status;
        bool derivativesAllowed;
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
        /// The parameter id
        ShortString tag;
        /// The type of the parameter, used to decode the value
        ParameterType paramType;
        /// Encoded according to paramType, might be empty.
        bytes defaultValue;
        /// If MultipleChoice, String[] of the available choices. Empty bytes otherwise.
        bytes availableChoices;
    }

    struct ParamValue {
        ShortString tag;
        bytes value;
    }

    struct FrameworkStorage {
        string textUrl;
        FixedSet.ShortStringSet paramTags;
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

    uint256 internal constant MAX_PARAM_TAGS = 150;

    /// Input for IpOrg legal terms configuration in LicensingModule (for now, the only option)
    bytes32 public constant LICENSING_FRAMEWORK_CONFIG = keccak256("LICENSING_FRAMEWORK_CONFIG");
    bytes32 public constant CREATE_LICENSE = keccak256("CREATE_LICENSE");
    bytes32 public constant ACTIVATE_LICENSE = keccak256("ACTIVATE_LICENSE");
    bytes32 public constant LINK_LNFT_TO_IPA = keccak256("LINK_LNFT_TO_IPA");

    function _statusToString(LicenseStatus status_) internal pure returns (string memory) {
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

    function _decodeMultipleChoice(
        bytes memory value,
        bytes memory availableChoices
    ) internal pure returns (ShortString[] memory) {
        uint256 mask = abi.decode(value, (uint256));
        uint8[] memory indexes = BitMask._getSetIndexes(mask);
        ShortString[] memory choices = abi.decode(availableChoices, (ShortString[]));
        ShortString[] memory result = new ShortString[](indexes.length);
        for (uint256 i = 0; i < indexes.length; i++) {
            result[i] = choices[indexes[i]];
        }
        return result;
    }

    function _encodeMultipleChoice(uint8[] memory choiceIndexes_) internal pure returns (bytes memory value) {
        uint256 mask = BitMask._convertToMask(choiceIndexes_);
        return abi.encode(mask);
    }

    function _validateParamValue(ParamDefinition memory paramDef_, bytes memory value_) internal pure returns (bool) {
        // An empty value signals the parameter is untagged, to trigger default values in the
        // license agreement text, but that's valid
        if (keccak256(value_) == keccak256("")) {
            return true;
        }
        if (paramDef_.paramType == Licensing.ParameterType.Bool) {
            abi.decode(value_, (bool));
            return true;
        } else if (paramDef_.paramType == Licensing.ParameterType.Number) {
            if (abi.decode(value_, (uint256)) == 0) {
                return false;
            }
        } else if (paramDef_.paramType == Licensing.ParameterType.Address) {
            // Not supporting address(0) as a valid value
            if (abi.decode(value_, (address)) == address(0)) {
                return false;
            }
        } else if (paramDef_.paramType == Licensing.ParameterType.String) {
            abi.decode(value_, (string));
            // WARNING: Do proper string validation off chain.
            if (
                keccak256(value_) == keccak256(abi.encode(" ")) ||
                keccak256(value_) == keccak256(abi.encode(""))
            ) {
                return false;
            }
        } else if (paramDef_.paramType == Licensing.ParameterType.ShortStringArray) {
            // WARNING: Do proper string validation off chain.
            ShortString[] memory result = abi.decode(value_, (ShortString[]));
            if (result.length == 0) {
                return false;
            }
        } else if (paramDef_.paramType == Licensing.ParameterType.MultipleChoice) {
            ShortString[] memory available = abi.decode(paramDef_.availableChoices, (ShortString[]));
            if (available.length == 0) {
                return false;
            }
        }
        return true;
    }

    function _shortStringArrayToJsonArray(ShortString[] memory ss) internal pure returns (string memory) {
        string memory result = "[";
        uint256 len = ss.length;
        for (uint256 i = 0; i < len; i++) {
            ShortString s = ss[i];
            result = string(abi.encodePacked(result, '"', s.toString(), '"'));
            if (i != len - 1) {
                result = string(abi.encodePacked(result, ','));
            }

        }
        return string(abi.encodePacked(result, "]"));
    }

    function _getDecodedParamString(Licensing.ParamDefinition memory paramDef_, bytes memory value_) internal pure returns (string memory) {
        if (paramDef_.paramType == Licensing.ParameterType.Bool) {
            return abi.decode(value_, (bool)) ? "true" : "false";
        } else if (paramDef_.paramType == Licensing.ParameterType.Number) {
            return Strings.toString(abi.decode(value_, (uint256)));
        } else if (paramDef_.paramType == Licensing.ParameterType.String) {
            return abi.decode(value_, (string));
        } else if (paramDef_.paramType == Licensing.ParameterType.Address) {
            address addr = abi.decode(value_, (address));
            return Strings.toHexString(uint160(addr), 20);
        } else if (paramDef_.paramType == Licensing.ParameterType.ShortStringArray) {
            ShortString[] memory choices = abi.decode(value_, (ShortString[]));
            return _shortStringArrayToJsonArray(choices);
        } else if (paramDef_.paramType == Licensing.ParameterType.MultipleChoice) {
            ShortString[] memory choices = _decodeMultipleChoice(value_, paramDef_.availableChoices);
            return _shortStringArrayToJsonArray(choices);
        }
        return "";
    }

}
