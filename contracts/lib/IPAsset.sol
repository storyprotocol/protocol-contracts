// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IPAsset } from "contracts/lib/IPAsset.sol";
import { Errors } from "./Errors.sol";

/// @title IP Asset Library
/// @notice Library for constants, structs, and helper functions for IP assets.
library IPAsset {
    uint8 public constant EXTERNAL_ASSET = type(uint8).max;

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

    /// @notice Struct for packing parameters related to IP asset registration.
    struct RegisterIpAssetParams {
        string name;
        uint64 ipAssetType;
        address owner;
        address ipOrg;
        bytes32 hash;
        string url;
        bytes data;
    }

    struct CreateIpAssetParams {
        IPAsset.IPAssetType ipAssetType;
        string name;
        string description;
        string mediaUrl;
        address to;
        uint256 parentIpOrgId;
        bytes collectData;
    }

    struct RegisterIPOrgParams {
        address registry;
        string name;
        string symbol;
        string description;
        string tokenURI;
    }

    struct InitIPOrgParams {
        address registry;
        address owner;
        string name;
        string symbol;
    }

    function _zeroId(IPAssetType ipAsset_) internal pure returns (uint256) {
        if (ipAsset_ == IPAssetType.UNDEFINED) {
            revert Errors.IPAsset_InvalidType(ipAsset_);
        }
        return _ID_RANGE * (uint256(ipAsset_) - 1);
    }

    function _lastId(IPAssetType ipAsset_) internal pure returns (uint256) {
        if (ipAsset_ == IPAssetType.UNDEFINED) {
            revert Errors.IPAsset_InvalidType(ipAsset_);
        }
        return (_ID_RANGE * uint256(ipAsset_)) - 1;
    }

    function _ipAssetTypeFor(uint256 id_) internal pure returns (IPAssetType) {
        // End of _ID_RANGE is zero (undefined) for each IPAsset
        // Also, we don't support ids higher than the last IPAsset enum item
        if (
            id_ % _ID_RANGE == 0 ||
            id_ > _ID_RANGE * (uint256(IPAssetType.ITEM))
        ) {
            return IPAssetType.UNDEFINED;
        }
        return IPAsset.IPAssetType((id_ / _ID_RANGE) + 1);
    }
}
