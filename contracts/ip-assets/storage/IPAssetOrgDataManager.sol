// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IPAsset } from "contracts/lib/IPAsset.sol";
import { Unauthorized, NonExistentID, ZeroAddress } from "contracts/errors/General.sol";
import { IIPAssetOrgDataManager } from "contracts/interfaces/ip-assets/storage/IIPAssetOrgDataManager.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IPAsset } from "contracts/lib/IPAsset.sol";

abstract contract IPAssetOrgDataManager is Initializable, IIPAssetOrgDataManager {

    /// @custom:storage-location erc7201:story-protocol.ip-asset-data.storage
    struct IPAssetDataStorage {
        mapping(uint256 => IPAssetData) ipAssetsData;
    }

    // keccak256(bytes.concat(bytes32(uint256(keccak256("story-protocol.ip-asset-data.storage")) - 1)))
    bytes32 private constant _STORAGE_LOCATION = 0x9d56f7e7ee381479643316c052563e5824551ecde3f8bff0aa320131666f6879;

    function __IPAssetData_init() public initializer {}

    function readIPAsset(uint256 ipAssetOrgId_) public view returns (IPAssetData memory) {
        IPAssetDataStorage storage $ = _getIPAssetDataStorage();
        return $.ipAssetsData[ipAssetOrgId_];
    }

    function _writeIPAsset(
        uint256 ipAssetId_,
        uint256 ipAssetOrgId_,
        string calldata name_,
        string calldata description_,
        string calldata mediaUrl_
    ) internal returns (IPAsset.IPAssetType) {
        IPAssetDataStorage storage $ = _getIPAssetDataStorage();
        IPAssetData storage ipAssetData = $.ipAssetsData[ipAssetOrgId_];
        if (ipAssetData.blockType == IPAsset.IPAssetType.UNDEFINED) {
            ipAssetData.blockType = IPAsset._ipAssetTypeFor(ipAssetOrgId_);
        }
        ipAssetData.name = name_;
        ipAssetData.description = description_;
        ipAssetData.mediaUrl = mediaUrl_;
        ipAssetData.ipAssetId = ipAssetId_;
        emit IPAssetWritten(ipAssetId_, ipAssetOrgId_, ipAssetData.blockType, name_, description_, mediaUrl_);
        return ipAssetData.blockType;
    }

    function _getIPAssetDataStorage() private pure returns (IPAssetDataStorage storage $) {
        assembly {
            $.slot := _STORAGE_LOCATION
        }
    }
    
}
