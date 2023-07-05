// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { LibIPAssetId } from "contracts/ip-assets/LibIPAssetId.sol";
import { Unauthorized, NonExistentID } from "contracts/errors/General.sol";
import { IIPAssetData } from "./IIPAssetData.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IPAsset } from "contracts/IPAsset.sol";

abstract contract IPAssetData is Initializable, IIPAssetData {

    error InvalidBlockType();

    /// @custom:storage-location erc7201:story-protocol.ip-asset-data.storage
    struct IPAssetDataStorage {
        mapping(uint256 => IPAssetData) IPAsset;
    }

    // keccak256(bytes.concat(bytes32(uint256(keccak256("story-protocol.ip-asset-data.storage")) - 1)))
    bytes32 private constant _STORAGE_LOCATION = 0x9d56f7e7ee381479643316c052563e5824551ecde3f8bff0aa320131666f6879;

    function __IPAssetData_init() public initializer {}

    function _getIPAssetDataStorage() private pure returns (IPAssetDataStorage storage $) {
        assembly {
            $.slot := _STORAGE_LOCATION
        }
    }

    function createIPAsset(
        IPAsset sb,
        string calldata name,
        string calldata _description,
        string calldata mediaUrl
    ) public returns (uint256) {
        if (sb == IPAsset.UNDEFINED) revert InvalidBlockType();
        uint256 sbId = _mintBlock(msg.sender, sb);
        _writeIPAsset(sbId, name, _description, mediaUrl);
        return sbId;
    }
    
    function _writeIPAsset(
        uint256 IPAssetId,
        string calldata name,
        string calldata description,
        string calldata mediaUrl
    ) private returns (IPAsset) {
        IPAssetDataStorage storage $ = _getIPAssetDataStorage();
        IPAssetData storage sbd = $.IPAsset[IPAssetId];
        if (sbd.blockType == IPAsset.UNDEFINED) {
            sbd.blockType = LibIPAssetId._IPAssetTypeFor(IPAssetId);
        }
        sbd.name = name;
        sbd.description = description;
        sbd.mediaUrl = mediaUrl;
        emit IPAssetWritten(IPAssetId, sbd.blockType, name, description, mediaUrl);
        return sbd.blockType;
    }

    function readIPAsset(uint256 IPAssetId) public view returns (IPAssetData memory) {
        IPAssetDataStorage storage $ = _getIPAssetDataStorage();
        return $.IPAsset[IPAssetId];
    }
    
    function _mintBlock(address to, IPAsset sb) internal virtual returns (uint256);
}