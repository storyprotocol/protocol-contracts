// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IPAsset } from "contracts/lib/IPAsset.sol";
import { Errors } from "./Errors.sol";

/// @title IP Asset Library
/// @notice Library for constants, structs, and helper functions for IP assets.
library IPAsset {

    uint8 constant EXTERNAL_ASSET = type(uint8).max;

    uint256 private constant _ID_RANGE = 10 ** 12;

    enum IPAssetType {
        UNDEFINED,
        STORY,
        CHARACTER,
        ART,
        GROUP,
        LOCATION,
        ITEM
    }

    function _zeroId(IPAssetType ipAsset) internal pure returns (uint256) {
        if (ipAsset == IPAssetType.UNDEFINED) revert Errors.IPAsset_InvalidType(ipAsset);
        return _ID_RANGE * (uint256(ipAsset) - 1);
    }

    function _lastId(IPAssetType ipAsset) internal pure returns (uint256) {
        if (ipAsset == IPAssetType.UNDEFINED) revert Errors.IPAsset_InvalidType(ipAsset);
        return (_ID_RANGE * uint256(ipAsset)) - 1;
    }

    function _ipAssetTypeFor(uint256 id) internal pure returns (IPAssetType) {
        // End of _ID_RANGE is zero (undefined) for each IPAsset
        // Also, we don't support ids higher than the last IPAsset enum item
        if (id % _ID_RANGE == 0 || id > _ID_RANGE * (uint256(IPAssetType.ITEM)))
            return IPAssetType.UNDEFINED;
        return IPAsset.IPAssetType((id / _ID_RANGE) + 1);
    }
}
