// SPDX-License-Identifier: UNLICENSED
// See https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.19;

import { Licensing } from "contracts/lib/modules/Licensing.sol";
import { ShortString, ShortStrings } from "@openzeppelin/contracts/utils/ShortStrings.sol";
import { Multicall } from "@openzeppelin/contracts/utils/Multicall.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { AccessControlled } from "contracts/access-control/AccessControlled.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { FixedSet } from "contracts/utils/FixedSet.sol";

/// @title Licensing Framework Repo
/// @notice Stores licensing frameworks and their parameters. License Modules
/// can use this repo to fetch the parameters of a framework in order encode and decode
/// them when creating Licenses
contract LicensingFrameworkRepo is AccessControlled, Multicall {
    using FixedSet for FixedSet.ShortStringSet;
    using ShortStrings for *;

    /// @notice Struct for storing the parameters of a licensing framework
    struct FrameworkStorage {
        /// @notice URL to the legal document of the framework
        string textUrl;
        /// @notice The tags of the parameters of the framework.
        FixedSet.ShortStringSet paramTags;
        /// @notice The definitions of the parameters of the framework
        Licensing.ParamDefinition[] paramDefs;
    }

    /// Emits when a new licensing framework is added
    event FrameworkAdded(string frameworkId, string textUrl);

    /// emits when a new parameter is added to a framework
    event ParamDefinitionAdded(string frameworkId, ShortString tag, Licensing.ParamDefinition definition);

    /// frameworkId => FrameworkStorage
    mapping(string => FrameworkStorage) private _frameworks;
    /// Hash of (frameworkId, tag) => ParamDefinition
    mapping(bytes32 => Licensing.ParamDefinition) private _frameworkDefs;

    /// @notice Constructor for the repo
    /// @param accessControl_ the address of the access control singleton contract
    constructor(address accessControl_) AccessControlled(accessControl_) {}

    /// @notice Adds a new licensing framework to the repo
    /// @dev this is an admin only function, and can only be called by the
    /// licensing manager role
    /// @param input_ the input parameters for the framework
    function addFramework(Licensing.SetFramework calldata input_) external onlyRole(AccessControl.LICENSING_MANAGER) {
        FrameworkStorage storage framework = _frameworks[input_.id];
        if (framework.paramTags.length() > 0) {
            revert Errors.LicensingFrameworkRepo_FrameworkAlreadyAdded();
        }
        uint256 numParams = input_.paramDefs.length;
        if (numParams > Licensing.MAX_PARAM_TAGS) {
            revert Errors.LicensingFrameworkRepo_TooManyParams();
        }
        for (uint256 i = 0; i < numParams; i++) {
            _addParameter(input_.id, input_.paramDefs[i]);
        }
        framework.textUrl = input_.textUrl;
        emit FrameworkAdded(input_.id, input_.textUrl);
    }

    /// @notice Adds a new parameter to a licensing framework
    /// @param frameworkId_ the ID of the framework
    /// @param paramDef_ the definition of the parameter
    function _addParameter(string calldata frameworkId_, Licensing.ParamDefinition calldata paramDef_) internal {
        FrameworkStorage storage framework = _frameworks[frameworkId_];
        ShortString tag = paramDef_.tag;
        if (framework.paramTags.contains(tag)) {
            revert Errors.LicensingFrameworkRepo_DuplicateParamType();
        }
        framework.paramTags.add(tag);
        _frameworkDefs[keccak256(abi.encode(frameworkId_, tag))] = paramDef_;
        framework.paramDefs.push(paramDef_);
        emit ParamDefinitionAdded(frameworkId_, tag, paramDef_);
    }

    /// Gets the URL to the legal document of a licensing framework
    function getLicenseTextUrl(string calldata frameworkId_) external view returns (string memory) {
        return _frameworks[frameworkId_].textUrl;
    }

    /// Gets the definition of a parameter of a licensing framework at a
    /// given index
    /// @param frameworkId_ the ID of the framework
    /// @param index the index of the parameter
    /// @return the definition of the parameter
    function getParamDefinitionAt(
        string calldata frameworkId_,
        uint256 index
    ) external view returns (Licensing.ParamDefinition memory) {
        FrameworkStorage storage framework = _frameworks[frameworkId_];
        return framework.paramDefs[index];
    }

    /// Gets the amount of parameters of a licensing framework
    /// @param frameworkId_ the ID of the framework
    /// @return the amount of parameters
    function getTotalParameters(string calldata frameworkId_) external view returns (uint256) {
        return _frameworks[frameworkId_].paramDefs.length;
    }

    /// Gets the definition of a parameter of a licensing framework for a
    /// given tag
    /// @param frameworkId_ the ID of the framework
    /// @param tag_ the tag of the parameter
    /// @return the definition of the parameter
    function getParamDefinition(
        string calldata frameworkId_,
        ShortString tag_
    ) external view returns (Licensing.ParamDefinition memory) {
        return _frameworkDefs[keccak256(abi.encode(frameworkId_, tag_))];
    }

    /// Gets all the parameter definitions of a licensing framework
    /// @dev Warning: this function can be expensive if the framework has
    /// many parameters
    /// @param frameworkId_ the ID of the framework
    /// @return the definitions of the parameters
    function getParameterDefs(string calldata frameworkId_) external view returns (Licensing.ParamDefinition[] memory) {
        return _frameworks[frameworkId_].paramDefs;
    }
}
