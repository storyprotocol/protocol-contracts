// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IPAsset, EXTERNAL_ASSET } from "contracts/IPAsset.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { LibIPAssetId } from "contracts/ip-assets/LibIPAssetId.sol";
import { IIPAssetRegistry } from "contracts/ip-assets/IIPAssetRegistry.sol";

/**
 * @title RelationshipTypeChecker
 * @dev Gives tools to check if the "endpoints" of a relationship are valid, according to the allowed asset types set in the relationship config.
 */
abstract contract RelationshipTypeChecker {

    error InvalidIPAssetArray();

    /**
     * @dev Checks if the source or destination type of a relationship is allowed by the relationship config.
     * @param collection The address of the collection of the relationship endpoint
     * @param id The id of the relationship endpoint
     * @param assetTypeMask The asset type mask of the relationship config, which contains the allowed asset types and the external asset flag
     * @return result Whether the relationship endpoint is valid
     * @return isAssetRegistry Whether the relationship endpoint is a Story Protocol IP Asset Registry
     */
    function _checkRelationshipNode(address collection, uint256 id, uint256 assetTypeMask) internal view returns (bool result, bool isAssetRegistry) {
        if (IERC721(collection).ownerOf(id) == address(0)) return (false, false);
        isAssetRegistry = _isAssetRegistry(collection);
        if (isAssetRegistry) {
            result = _supportsIPAssetType(assetTypeMask, uint8(LibIPAssetId._ipAssetTypeFor(id)));
        } else {
            result = _supportsIPAssetType(assetTypeMask, EXTERNAL_ASSET);
        }
        return (result, isAssetRegistry);
    }

    /// must return true if the address is a Story Protocol IP Asset Registry
    function _isAssetRegistry(address ipAssetRegistry) internal virtual view returns(bool);

    /**
     * @dev converts an array of IPAssets types and the allows external flag to a mask, by setting the bits corresponding
     * to the uint8 equivalent of the IPAsset types to 1.
     * @param ipAssets The array of IPAsset types
     * @param allowsExternal Whether the relationship config allows external (non SP ERC721) assets
     * @return mask The mask representing the IPAsset types and the allows external flag
     */
    function _convertToMask(IPAsset[] calldata ipAssets, bool allowsExternal) internal pure returns (uint256) {
        if (ipAssets.length == 0) revert InvalidIPAssetArray();
        uint256 mask = 0;
        for (uint256 i = 0; i < ipAssets.length;) {
            if (ipAssets[i] == IPAsset.UNDEFINED) revert InvalidIPAssetArray();
            mask |= 1 << (uint256(ipAssets[i]) & 0xff);
            unchecked {
                i++;
            }
        }
        if (allowsExternal) {
            mask |= uint256(EXTERNAL_ASSET) << 248;
        }
        return mask;
    }

    /// returns true if the asset type is supported by the mask, false otherwise
    function _supportsIPAssetType(uint256 mask, uint8 assetType) internal pure returns (bool) {
        return mask & (1 << (uint256(assetType) & 0xff)) != 0;
    }

}