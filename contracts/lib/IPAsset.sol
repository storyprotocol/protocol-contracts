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
        bytes32 hash;
    }

    struct CreateIpAssetParams {
        IPAsset.IPAssetType ipOrgAssetType;
        uint64 ipAssetType;
        string name;
        bytes32 hash;
        string mediaUrl;
        bytes ipData;
    }

}
