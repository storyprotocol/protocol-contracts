// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { Licensing } from "contracts/lib/modules/Licensing.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { ShortString, ShortStrings } from "@openzeppelin/contracts/utils/ShortStrings.sol";
import { Multicall } from "@openzeppelin/contracts/utils/Multicall.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { IHook } from "contracts/interfaces/hooks/base/IHook.sol";
import { AccessControlled } from "contracts/access-control/AccessControlled.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { FixedSet } from "contracts/utils/FixedSet.sol";


contract LicensingFrameworkRepo is AccessControlled, Multicall {
    using FixedSet for FixedSet.ShortStringSet;
    using ShortStrings for *;

    event FrameworkAdded(
        string frameworkId,
        string textUrl
    );

    event ParamDefinitionAdded(
        string frameworkId,
        ShortString tag,
        Licensing.ParameterType paramType
    );

    mapping(string => Licensing.FrameworkStorage) private _frameworks;

    constructor(address accessControl_) AccessControlled(accessControl_) {}

    function addFramework(
        Licensing.SetFramework calldata input_
    ) external onlyRole(AccessControl.LICENSING_MANAGER) {
        if (_frameworks[input_.id].paramTags.length() > 0) {
            revert Errors.LicensingFrameworkRepo_FrameworkAlreadyAdded();
        }
        uint256 numParams = input_.paramDefs.length;
        if (numParams > Licensing.MAX_PARAM_TAGS) {
            revert Errors.LicensingFrameworkRepo_TooManyParams();
        }
        for (uint256 i = 0; i < numParams; i++) {
            _addParameter(input_.id, input_.paramDefs[i]);
        }
        _frameworks[input_.id].textUrl = input_.textUrl;
        emit FrameworkAdded(input_.id, input_.textUrl);
    }

    function _addParameter(
        string calldata frameworkId_,
        Licensing.ParamDefinition calldata paramDef_
    ) internal {
        Licensing.FrameworkStorage storage framework = _frameworks[frameworkId_];
        ShortString tag = paramDef_.tag;
        if (framework.paramTags.contains(tag)) {
            revert Errors.LicensingFrameworkRepo_DuplicateParamType();
        }
        framework.paramTags.add(tag);
        framework.paramTypes[tag] = paramDef_.paramType;
        emit ParamDefinitionAdded(frameworkId_, tag, paramDef_.paramType);
    } 


    function validateParamValues(
        string calldata frameworkId_,
        Licensing.ParamValue[] calldata params_
    ) external view returns(bool) {
        Licensing.FrameworkStorage storage framework = _frameworks[frameworkId_];
        uint256 numParams = params_.length;
        if (numParams == 0 || numParams > Licensing.MAX_PARAM_TAGS) {
            return false;
        }
        for (uint256 i = 0; i < numParams; i++) {
            ShortString tag = params_[i].tag;
            if (!framework.paramTags.contains(tag)) {
                return false;
            }
            if (!validateParamValue(framework.paramTypes[tag], params_[i].value)) {
                return false;
            }
        }
        return true;
    }

    function validateParamValue(Licensing.ParameterType pType, bytes calldata value) view public returns(bool) {
        // An empty value signals the parameter is untagged, to trigger default values in the
        // license agreement text
        if (keccak256(value) == keccak256("")) {
            return false;
        }
        if (pType == Licensing.ParameterType.Bool) {
            abi.decode(value, (bool));
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
            // Empty string is checked above
            // Do proper string validation off chain, Solidity is not great at it
            if (
                keccak256(value) == keccak256(abi.encode(" ")) ||
                keccak256(value) == keccak256(abi.encode(""))
            ) {
                return false;
            }
        } else if (pType == Licensing.ParameterType.MultipleChoice) {
            ShortString[] memory ssValue = abi.decode(value, (ShortString[]));
            // No choice is not a valid value, if you need this have a value called
            // "None" or something
            if (ssValue.length == 0) {
                return false;
            }
        }
        return true;
    }

    function getLicenseTextUrl(
        string calldata frameworkId_
    ) external view returns (string memory) {
        return _frameworks[frameworkId_].textUrl;
    }

    function getParamDefinitionAt(
        string calldata frameworkId_,
        uint256 index
    ) external view returns (Licensing.ParamDefinition memory) {
        Licensing.FrameworkStorage storage framework = _frameworks[
            frameworkId_
        ];
        ShortString tag = framework.paramTags.at(index);
        return Licensing.ParamDefinition({ tag: tag, paramType: framework.paramTypes[tag] });
    }

    function getTotalParameters(
        string calldata frameworkId_
    ) external view returns (uint256) {
        return _frameworks[frameworkId_].paramTags.length();
    }
}
