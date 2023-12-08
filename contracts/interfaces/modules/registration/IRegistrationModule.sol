// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IModule } from "contracts/interfaces/modules/base/IModule.sol";

/// @title IRegistrationModule
interface IRegistrationModule is IModule {
    /// @notice Emits when an IPOrg updates metadata associated with its IPA.
    /// @param ipOrg The address of the IP Org whose metadata was updated.
    /// @param baseURI The base token URI to be used for token metadata.
    /// @param contractURI The contract URI to be used for contract metadata.
    event MetadataUpdated(address indexed ipOrg, string baseURI, string contractURI);

    /// @notice Emits when a new IP asset is registered.
    /// @param ipAssetId The identifier of the newly registered IP asset.
    /// @param ipOrg The address of the IP Org of the IP asset.
    /// @param ipOrgAssetId The IP Org localized id of the IP asset.
    /// @param owner The address of the new IP asset owner.
    /// @param name The name of the IP asset being registered.
    /// @param ipOrgAssetType The numerical id of the IP asset type.
    /// @param hash The content hash of the registered IP asset.
    /// @param mediaUrl The media URL of the registered IP asset.
    event IPAssetRegistered(
        uint256 ipAssetId,
        address indexed ipOrg,
        uint256 ipOrgAssetId,
        address indexed owner,
        string name,
        uint8 indexed ipOrgAssetType,
        bytes32 hash,
        string mediaUrl
    );

    /// @notice Emits when an IP asset is transferred to a new owner.
    /// @param ipAssetId The identifier of the IP asset being transferred.
    /// @param ipOrg The address of the IP Org which administers the IP asset.
    /// @param ipOrgAssetId The local id of the wrapped IP within the IP Org.
    /// @param prevOwner The address of the previous owner of the IP asset.
    /// @param newOwner The address of the new owner of the IP asset.
    event IPAssetTransferred(
        uint256 indexed ipAssetId,
        address indexed ipOrg,
        uint256 ipOrgAssetId,
        address prevOwner,
        address newOwner
    );

    /// @notice Returns the current owner of an IP asset.
    /// @param ipAssetId_ The global identifier of the IP asset within the GIPR.
    function ownerOf(uint256 ipAssetId_) external view returns (address);

    /// @notice Gets the IP asset id associated with an IP Org asset.
    /// @param ipOrg_ The address of the governing IP asset IP Org.
    /// @param ipOrgAssetId_ The localized id of the IP asset within the IP Org.
    function ipAssetId(address ipOrg_, uint256 ipOrgAssetId_) external returns (uint256);

    /// @notice Renders metadata of an IP Asset localized for an IP Org.
    /// @param ipOrg_ The address of the IP Org of the IP asset.
    /// @param ipOrgAssetId_ The local id of the IP asset within the IP Org.
    /// @param ipOrgAssetType_ The IP Org asset type.
    /// @return The token URI associated with the IP Org.
    function tokenURI(
        address ipOrg_,
        uint256 ipOrgAssetId_,
        uint8 ipOrgAssetType_
    ) external view returns (string memory);

    /// @notice Gets the contract URI for an IP Org.
    /// @param ipOrg_ The address of the IP Org.
    /// @return The contract URI associated with the IP Org.
    function contractURI(address ipOrg_) external view returns (string memory);

    /// @notice get the ip Asset types of an ipOrg
    function getIpOrgAssetTypes(address ipOrg_) external view returns (string[] memory);

    /// @notice Returns true if the index for an IP Org asset type is supported.
    function isValidIpOrgAssetType(address ipOrg_, uint8 index) external view returns (bool);
}
