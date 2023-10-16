// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

/// @title IP Asset Registry
/// @notice The source of truth for IP on Story Protocol.
contract IPAssetRegistry {

    /// @notice Core attributes that make up an IP Asset.
    // TO-DO: Change core record primitives and deprecate use of ipAssetGroupId.
    struct Record {
        address owner;
        address ipAssetGroup;
        uint256 ipAssetGroupId;
    }

    /// @notice Mapping from IP asset ids to registry records.
    mapping(uint256 => Record) registry;

    /// @notice Tracks the total number of IP Assets in existence.
    uint256 numIPAssets = 0;

    /// @notice Registers a new IPAsset 
    // TO-DO: Add registration authorization (likely based around IPAssetGroup enrollment).
    function register(address owner_, address ipAssetGroup_, uint256 ipAssetGroupId_) public {
        registry[numIPAssets++] = Record({
            owner: owner_,
            ipAssetGroup: ipAssetGroup_,
            ipAssetGroupId: ipAssetGroupId_
        });
    }

}
