// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { LibIPAssetId } from "contracts/ip-assets/LibIPAssetId.sol";
import { Unauthorized, NonExistentID, ZeroAddress } from "contracts/errors/General.sol";
import { IIPAssetDataManager } from "contracts/interfaces/ip-assets/storage/IIPAssetDataManager.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IPAsset } from "contracts/IPAsset.sol";

abstract contract IPAssetDataManager is Initializable, IIPAssetDataManager {

    error InvalidBlockType();

    /// @custom:storage-location erc7201:story-protocol.ip-asset-data.storage
    struct IPAssetDataStorage {
        mapping(uint256 => IPAssetData) ipAssetsData;
    }

    // keccak256(bytes.concat(bytes32(uint256(keccak256("story-protocol.ip-asset-data.storage")) - 1)))
    bytes32 private constant _STORAGE_LOCATION = 0x9d56f7e7ee381479643316c052563e5824551ecde3f8bff0aa320131666f6879;

    function __IPAssetData_init() public initializer {}

    function _getIPAssetDataStorage() private pure returns (IPAssetDataStorage storage $) {
        assembly {
            $.slot := _STORAGE_LOCATION
        }
    }
    
    function _writeIPAsset(
        uint256 ipAssetId,
        string calldata name,
        string calldata description,
        string calldata mediaUrl
    ) internal returns (IPAsset) {
        IPAssetDataStorage storage $ = _getIPAssetDataStorage();
        IPAssetData storage sbd = $.ipAssetsData[ipAssetId];
        if (sbd.blockType == IPAsset.UNDEFINED) {
            sbd.blockType = LibIPAssetId._ipAssetTypeFor(ipAssetId);
        }
        sbd.name = name;
        sbd.description = description;
        sbd.mediaUrl = mediaUrl;
        emit IPAssetWritten(ipAssetId, sbd.blockType, name, description, mediaUrl);
        return sbd.blockType;
    }

    function readIPAsset(uint256 ipAssetId) public view returns (IPAssetData memory) {
        IPAssetDataStorage storage $ = _getIPAssetDataStorage();
        return $.ipAssetsData[ipAssetId];
    }
    
}