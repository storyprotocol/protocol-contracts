// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IPAsset } from "contracts/lib/IPAsset.sol";
import { Unauthorized, NonExistentID, ZeroAddress } from "contracts/errors/General.sol";
import { IIPAssetGroupDataManager } from "contracts/interfaces/ip-assets/storage/IIPAssetGroupDataManager.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IPAsset } from "contracts/lib/IPAsset.sol";

abstract contract IPAssetGroupDataManager is Initializable, IIPAssetGroupDataManager {

    /// @custom:storage-location erc7201:story-protocol.ip-asset-data.storage
    struct IPAssetDataStorage {
        mapping(uint256 => IPAssetData) ipAssetsData;
    }

    // keccak256(bytes.concat(bytes32(uint256(keccak256("story-protocol.ip-asset-data.storage")) - 1)))
    bytes32 private constant _STORAGE_LOCATION = 0x9d56f7e7ee381479643316c052563e5824551ecde3f8bff0aa320131666f6879;

    function __IPAssetData_init() public initializer {}

    function readIPAsset(uint256 ipAssetGroupId_) public view returns (IPAssetData memory) {
        IPAssetDataStorage storage $ = _getIPAssetDataStorage();
        return $.ipAssetsData[ipAssetGroupId_];
    }

    function _writeIPAsset(
        uint256 ipAssetGroupId_,
        string calldata name_,
        string calldata description_,
        string calldata mediaUrl_
    ) internal returns (IPAsset.IPAssetType) {
        IPAssetDataStorage storage $ = _getIPAssetDataStorage();
        IPAssetData storage ipAsseData = $.ipAssetsData[ipAssetGroupId_];
        if (ipAsseData.blockType == IPAsset.IPAssetType.UNDEFINED) {
            ipAsseData.blockType = IPAsset._ipAssetTypeFor(ipAssetGroupId_);
        }
        ipAsseData.name = name_;
        ipAsseData.description = description_;
        ipAsseData.mediaUrl = mediaUrl_;
        emit IPAssetWritten(ipAssetGroupId_, ipAsseData.blockType, name_, description_, mediaUrl_);
        return ipAsseData.blockType;
    }

    function _getIPAssetDataStorage() private pure returns (IPAssetDataStorage storage $) {
        assembly {
            $.slot := _STORAGE_LOCATION
        }
    }
    
}
