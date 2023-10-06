// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IPAsset, EXTERNAL_ASSET } from "contracts/IPAsset.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { LibIPAssetID } from "contracts/ip-assets/LibIPAssetID.sol";
import { IIPAssetRegistry } from "contracts/interfaces/ip-assets/IIPAssetRegistry.sol";


/// @title LibIPAssetMask
/// @dev Gives tools to check if the "endpoints" of a relationship are valid, according to the allowed asset types set in the relationship config.
library LibIPAssetMask {

    error InvalidIPAssetArray();

    
    /// @dev converts an array of IPAssets types and the allows external flag to a mask, by setting the bits corresponding
    /// to the uint8 equivalent of the IPAsset types to 1.
    /// @param ipAssets_ The array of IPAsset types
    /// @param allowsExternal_ Whether the relationship config allows external (non SP ERC721) assets
    /// @return mask The mask representing the IPAsset types and the allows external flag
    function _convertToMask(IPAsset[] calldata ipAssets_, bool allowsExternal_) internal pure returns (uint256) {
        if (ipAssets_.length == 0) revert InvalidIPAssetArray();
        uint256 mask = 0;
        for (uint256 i = 0; i < ipAssets_.length;) {
            if (ipAssets_[i] == IPAsset.UNDEFINED) revert InvalidIPAssetArray();
            mask |= 1 << (uint256(ipAssets_[i]) & 0xff);
            unchecked {
                i++;
            }
        }
        if (allowsExternal_) {
            mask |= uint256(EXTERNAL_ASSET) << 248;
        }
        return mask;
    }

    
    /// @dev converts a mask to an array of IPAsset types and the allows external flag, by checking the bits corresponding
    /// to the uint8 equivalent of the IPAsset types.
    /// NOTE: Caller must ignore the array elements of value 0
    /// @param mask_ The mask representing the IPAsset types and the allows external flag
    /// @return ipAssets The array of IPAsset types. NOTE: Ignore the array elements of value 0
    /// @return allowsExternal Whether the relationship config allows external (non SP ERC721) assets
    function _convertFromMask(uint256 mask_) internal pure returns (IPAsset[] memory ipAssets, bool allowsExternal) {
        ipAssets = new IPAsset[](8);
        uint256 index = 0;
        for (uint256 i = 1; i < 8; i++) {
            if (mask_ & (1 << i) != 0) {
                ipAssets[index] = IPAsset(i);
                index++;
            }
        }
        allowsExternal = mask_ & (1 << 248) != 0;
        return (ipAssets, allowsExternal);
    }

    
    /// returns true if the asset type is supported by the mask, false otherwise
    function _supportsIPAssetType(uint256 mask_, uint8 assetType_) internal pure returns (bool) {
        return mask_ & (1 << (uint256(assetType_) & 0xff)) != 0;
    }

    
    /// @dev checks if the asset type of the asset is supported by the mask
    /// @param isAssetRegistry_ Whether the asset is an SP asset registry or an external asset
    /// @param assetId_ The asset id
    /// @param assetTypeMask_ The mask representing the IPAsset types and the allows external flag
    /// @return result true if mask test passes, false otherwise
    function _checkRelationshipNode(bool isAssetRegistry_, uint256 assetId_, uint256 assetTypeMask_) internal pure returns (bool result) {
        if (isAssetRegistry_) {
            result = LibIPAssetMask._supportsIPAssetType(assetTypeMask_, uint8(LibIPAssetID._ipAssetTypeFor(assetId_)));
        } else {
            result = LibIPAssetMask._supportsIPAssetType(assetTypeMask_, EXTERNAL_ASSET);
        }
        return result;
    }

}