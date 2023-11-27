// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { Registration } from "contracts/lib/modules/Registration.sol";

/// @title IRegistrationModule
interface IRegistrationModule {

    /// @notice Emits when an IPOrg updates metadata associated with its IPA.
    /// @param ipOrg_ The address of the IP Org whose metadata was updated.
    /// @param baseURI_ The base token URI to be used for token metadata.
    /// @param contractURI_ The contract URI to be used for contract metadata.
    event MetadataUpdated(
        address indexed ipOrg_,
        string baseURI_,
        string contractURI_
    );

    /// @notice Emits when a new IP asset is registered.
    /// @param ipAssetId_ The identifier of the newly registered IP asset.
    /// @param ipOrg_ The address of the IP Org of the IP asset.
    /// @param ipOrgAssetId_ The IP Org localized id of the IP asset.
    /// @param owner_ The address of the new IP asset owner.
    /// @param name_ The name of the IP asset being registered.
    /// @param ipOrgAssetType_ The numerical id of the IP asset type.
    /// @param hash_ The content hash of the registered IP asset.
    /// @param mediaUrl_ The media URL of the registered IP asset.
    event IPAssetRegistered(
        uint256 ipAssetId_,
        address indexed ipOrg_,
        uint256 ipOrgAssetId_,
        address indexed owner_,
        string name_,
        uint8 indexed ipOrgAssetType_,
        bytes32 hash_,
        string mediaUrl_
    );

    /// @notice Emits when an IP asset is transferred to a new owner.
    /// @param ipAssetId_ The identifier of the IP asset being transferred.
    /// @param ipOrg_ The address of the IP Org which administers the IP asset.
    /// @param ipOrgAssetId_ The local id of the wrapped IP within the IP Org.
    /// @param prevOwner_ The address of the previous owner of the IP asset.
    /// @param newOwner_ The address of the new owner of the IP asset.
    event IPAssetTransferred(
        uint256 indexed ipAssetId_,
        address indexed ipOrg_,
        uint256 ipOrgAssetId_,
        address prevOwner_,
        address newOwner_
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
    function tokenURI(address ipOrg_, uint256 ipOrgAssetId_, uint8 ipOrgAssetType_) external view returns (string memory);

    /// @notice Gets the contract URI for an IP Org.
    /// @param ipOrg_ The address of the IP Org.
    /// @return The contract URI associated with the IP Org.
    function contractURI(address ipOrg_) external view returns (string memory);

    /// @notice get the ip Asset types of an ipOrg
    function getIpOrgAssetTypes(address ipOrg_) external view returns (string[] memory);

    /// @notice Returns true if the index for an IP Org asset type is supported.
    function isValidIpOrgAssetType(address ipOrg_, uint8 index) external view returns (bool);
}
