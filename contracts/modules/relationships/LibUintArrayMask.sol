// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IPAsset } from "contracts/lib/IPAsset.sol";
import { IIPOrg } from "contracts/interfaces/ip-org/IIPOrg.sol";
import { Errors } from "contracts/lib/Errors.sol";

/// @title LibUintArrayMask
/// @dev Gives tools to check if the "endpoints" of a relationship are valid, according to the allowed asset types set in the relationship config.
library LibUintArrayMask {

    uint8 public constant UNDEFINED = 0;

    /// @dev converts an array of types and the allows external flag to a mask, by setting the bits corresponding
    /// to the uint8 equivalent of the IPAsset types to 1.
    /// @param assetTypes_ The array of subType
    /// @return mask The mask representing the IPAsset types and the allows external flag
    function _convertToMask(uint8[] calldata assetTypes_) internal pure returns (uint256) {
        if (assetTypes_.length == 0) revert Errors.LibUintArrayMask_EmptyArray();
        uint256 mask = 0;
        for (uint256 i = 0; i < assetTypes_.length;) {
            if (assetTypes_[i] == UNDEFINED) revert Errors.LibUintArrayMask_UndefinedArrayElement();
            mask |= 1 << (uint256(assetTypes_[i]) & 0xff);
            unchecked {
                i++;
            }
        }
        return mask;
    }

    /// returns true if the asset type is supported by the mask, false otherwise
    function _isAssetTypeOnMask(uint256 mask_, uint8 assetType_) internal pure returns (bool) {
        return mask_ & (1 << (uint256(assetType_) & 0xff)) != 0;
    }

}
