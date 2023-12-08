// SPDX-License-Identifier: UNLICENSED
// See https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.19;

import { BitMask } from "contracts/lib/BitMask.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ShortStrings, ShortString } from "@openzeppelin/contracts/utils/ShortStrings.sol";

/// @title Licensing Module Library
library Licensing {
    using ShortStrings for *;
    /// @notice Enum for the status of a license.
    enum LicenseStatus {
        /// No status has been set.
        Unset,
        /// The license is active. It can be linked with IPAs.
        Active,
        /// The license is pending licensor approval. It can't be linked with IPAs until approved
        /// by the licensor using the LicensingModule (activateLicense)
        PendingLicensorApproval,
        /// The license has been revoked. It can't be linked with IPAs or sublicensed.
        /// Sub-licenses will be considered non active.
        Revoked
    }

    /// @notice Defines the types to encode/decode the parameters of a licensing framework.
    enum ParameterType {
        /// Boolean value
        Bool,
        /// Number value (18 decimals)
        Number,
        /// Address value
        Address,
        /// String value
        String,
        /// Array of ShortString values
        ShortStringArray,
        // uint256 bitmask representing indexes in choices array. ParamDefinition will have the available choices array.
        MultipleChoice
    }

    /// @notice Defines the configuration of the licensor for an IP org.
    enum LicensorConfig {
        /// Null value.
        Unset,
        /// Licensor is the IP org owner, for all licenses.
        IpOrgOwnerAlways,
        /// Licensor will be:
        /// - If parentLicense is provided, the licensee of the parent license.
        /// - If parentLicense is not provided, the Owner of the linked IPA.
        /// - If no parentLicense and no linked IPA, the IP org owner.
        Source
    }

    /// @notice Data struct representing a license agreement minted according to an IP Org Licensing Framework
    struct LicenseData {
        /// License status.
        LicenseStatus status;
        /// If true, other licenses can set this one as parent license, false will prevent it.
        bool derivativesAllowed;
        /// If true, sublicenses can be created by anyone, and the terms of this license will be
        /// applied to the sublicenses. If false, sublicenses can only be created by the licensor.
        bool isReciprocal;
        /// If true, sublicenses will be minted with LicenseStatus.PendingLicensorApproval.
        bool derivativeNeedsApproval;
        /// Address with permission to revoke the license.
        address revoker;
        /// address granting the license
        address licensor;
        /// address of the ip org that produced the terms
        address ipOrg;
        /// The id of the license framework used to mint this license
        ShortString frameworkId;
        /// If the licensee is linked to an IPA, this is the IPA id. 0 otherwise
        uint256 ipaId;
        /// The id of the parent license, if any. 0 otherwise
        uint256 parentLicenseId;
    }

    /// @notice Parameters to mint a license
    struct LicenseCreation {
        /// Array of (tag, value) pairs for the parameters, corresponding to the tags in the
        /// licensing framework.
        ParamValue[] params;
        /// Parent license id, if any. 0 otherwise.
        uint256 parentLicenseId;
        /// Linked IPA id, if any. 0 otherwise.
        uint256 ipaId;
    }

    /// @notice Corresponds to a parameter (licensing term) of a licensing framework.
    struct ParamDefinition {
        /// The parameter id, used to identify the parameter in the license agreement text.
        ShortString tag;
        /// The type of the parameter, used to encode/decode the value
        ParameterType paramType;
        /// Encoded according to paramType, might be empty.
        bytes defaultValue;
        /// If MultipleChoice, String[] of the available choices. Empty bytes otherwise.
        bytes availableChoices;
    }

    /// @notice Corresponds to a value for parameter (licensing term) of a licensing framework.
    struct ParamValue {
        /// The parameter id, used to identify the parameter in the license agreement text.
        ShortString tag;
        /// Encoded according to paramType, might be empty.
        bytes value;
    }

    /// @notice Parameters to set a licensing framework in LicensingFrameworkRepo
    struct SetFramework {
        /// The id of the licensing framework.
        string id;
        /// The URL to the license agreement text.
        string textUrl;
        /// Array of parameter definitions, corresponding to the parameters in
        /// the license agreement text.
        ParamDefinition[] paramDefs;
    }

    /// @notice Parameters to set a licensing framework in an IP org
    struct LicensingConfig {
        /// The id of the licensing framework.
        string frameworkId;
        /// Array of (tag, value) pairs for the parameters, corresponding to the tags in the
        /// licensing framework.
        ParamValue[] params;
        /// Enum with the rules to determine the licensor for this IP org's licenses
        LicensorConfig licensor;
    }

    /// @notice Maximum number of parameters allowed in a licensing framework.
    uint256 public constant MAX_PARAM_TAGS = 255;

    /// Input for IpOrg legal terms configuration in LicensingModule (for now, the only option)
    bytes32 public constant LICENSING_FRAMEWORK_CONFIG = keccak256("LICENSING_FRAMEWORK_CONFIG");
    /// Create license action in LicensingModule
    bytes32 public constant CREATE_LICENSE = keccak256("CREATE_LICENSE");
    /// Activate license action in LicensingModule
    bytes32 public constant ACTIVATE_LICENSE = keccak256("ACTIVATE_LICENSE");
    /// Revoke license action in LicensingModule
    bytes32 public constant LINK_LNFT_TO_IPA = keccak256("LINK_LNFT_TO_IPA");

    /// @notice Returns the string representation of a license status.
    function statusToString(LicenseStatus status_) internal pure returns (string memory) {
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

    /// @notice decodes value from a MultipleChoice parameter into the corresponding ShortString[]
    /// with the choices
    /// @param value the encoded value
    /// @param availableChoices the encoded available choices for the parameter, defined in parameter
    /// definition
    function decodeMultipleChoice(
        bytes memory value,
        bytes memory availableChoices
    ) internal pure returns (ShortString[] memory) {
        uint256 mask = abi.decode(value, (uint256));
        uint8[] memory indexes = BitMask.getSetIndexes(mask);
        ShortString[] memory choices = abi.decode(availableChoices, (ShortString[]));
        ShortString[] memory result = new ShortString[](indexes.length);
        for (uint256 i = 0; i < indexes.length; i++) {
            result[i] = choices[indexes[i]];
        }
        return result;
    }

    /// @notice Sets the indexes for the chosen options in a MultipleChoice parameter,
    /// and encodes it into bytes
    /// @param choiceIndexes_ the indexes of the chosen options
    /// @return value the encoded value
    function encodeMultipleChoice(uint8[] memory choiceIndexes_) internal pure returns (bytes memory value) {
        uint256 mask = BitMask.convertToMask(choiceIndexes_);
        return abi.encode(mask);
    }

    /// @notice Validates the value for a parameter, according to its type, meaning it will
    /// decode the value and try to revert if it's not valid.
    /// @dev WARNING: Some validations are not possible to do on chain (like string validation),
    /// so they should be done off chain. Also, Boolean decoded as a Number will be valid.
    /// @param paramDef_ the parameter definition
    /// @param value_ the encoded value
    function validateParamValue(ParamDefinition memory paramDef_, bytes memory value_) internal pure returns (bool) {
        // An empty value signals the parameter is untagged, to trigger default values in the
        // license agreement text, but that's valid
        if (keccak256(value_) == keccak256("")) {
            return true;
        }
        if (paramDef_.paramType == Licensing.ParameterType.Bool) {
            abi.decode(value_, (bool));
            return true;
        } else if (paramDef_.paramType == Licensing.ParameterType.Number && abi.decode(value_, (uint256)) == 0) {
            return false;
        } else if (
            paramDef_.paramType == Licensing.ParameterType.Address &&
            // Not supporting address(0) as a valid value
            abi.decode(value_, (address)) == address(0)
        ) {
            return false;
        } else if (
            paramDef_.paramType == Licensing.ParameterType.String &&
            (keccak256(abi.encodePacked(abi.decode(value_, (string)))) == keccak256(abi.encode(" ")) ||
                keccak256(abi.encodePacked(abi.decode(value_, (string)))) == keccak256(abi.encode("")))
        ) {
            return false;
        } else if (
            paramDef_.paramType == Licensing.ParameterType.ShortStringArray &&
            abi.decode(value_, (ShortString[])).length == 0
        ) {
            return false;
        } else if (
            paramDef_.paramType == Licensing.ParameterType.MultipleChoice &&
            abi.decode(paramDef_.availableChoices, (ShortString[])).length == 0
        ) {
            return false;
        }
        return true;
    }

    /// @notice converts a ShortString[] to a string representation of a JSON array. Used for LicenseRegistry
    /// metadata rendering.
    /// @param ss the ShortString[]
    /// @return the string representation of a JSON array
    function shortStringArrayToJsonArray(ShortString[] memory ss) internal pure returns (string memory) {
        string memory result = "[";
        uint256 len = ss.length;
        for (uint256 i = 0; i < len; i++) {
            ShortString s = ss[i];
            result = string(abi.encodePacked(result, "\"", s.toString(), "\"")); // solhint-disable-line
            if (i != len - 1) {
                result = string(abi.encodePacked(result, ","));
            }
        }
        return string(abi.encodePacked(result, "]"));
    }

    /// @notice decodes value from a parameter into a string representation that can be used
    /// in LicenseRegistry metadata rendering.
    /// @param paramDef_ the parameter definition
    /// @param value_ the encoded value
    /// @return the string representation of the value
    function getDecodedParamString(
        Licensing.ParamDefinition memory paramDef_,
        bytes memory value_
    ) internal pure returns (string memory) {
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
            return shortStringArrayToJsonArray(choices);
        } else if (paramDef_.paramType == Licensing.ParameterType.MultipleChoice) {
            ShortString[] memory choices = decodeMultipleChoice(value_, paramDef_.availableChoices);
            return shortStringArrayToJsonArray(choices);
        }
        return "";
    }
}
