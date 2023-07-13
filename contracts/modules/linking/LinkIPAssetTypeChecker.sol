// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IPAsset } from "contracts/IPAsset.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { LibIPAssetId } from "contracts/ip-assets/LibIPAssetId.sol";
import { IIPAssetRegistry } from "contracts/ip-assets/IIPAssetRegistry.sol";

abstract contract LinkIPAssetTypeChecker {

    error InvalidIPAssetArray();

    uint8 private constant _EXTERNAL_ASSET_TYPE = type(uint8).max;


    function _checkLinkEnd(address collection, uint256 id, uint256 assetTypeMask) internal view returns (bool) {
        if (IERC721(collection).ownerOf(id) == address(0)) return false;
        if (_isAssetRegistry(collection)) {
            return _supportsIPAssetType(assetTypeMask, _EXTERNAL_ASSET_TYPE);
        } else {
            return _supportsIPAssetType(assetTypeMask, uint8(LibIPAssetId._ipAssetTypeFor(id)));
        }
    }

    function _isAssetRegistry(address ipAssetRegistry) internal virtual view returns(bool);

    function _convertToMask(IPAsset[] calldata ipAssets, bool allowsExternal) internal pure returns (uint256) {
        if (ipAssets.length == 0) revert InvalidIPAssetArray();
        uint256 mask = 0;
        for (uint256 i = 0; i < ipAssets.length;) {
            if (ipAssets[i] == IPAsset.UNDEFINED) revert InvalidIPAssetArray();
            mask |= uint256(ipAssets[i]);
            unchecked {
                i++;
            }
        }
        if (allowsExternal) {
            mask |= uint256(_EXTERNAL_ASSET_TYPE);
        }
        return mask;
    }

    function _supportsIPAssetType(uint256 mask, uint8 assetType) internal pure returns (bool) {
        return (mask & uint256(assetType)) != 0;
    }

}