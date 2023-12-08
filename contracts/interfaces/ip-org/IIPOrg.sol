// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice IP Org Interface
interface IIPOrg {
    /// @notice Returns the current owner of the IP asset within the IP Org.
    /// @return The address of the owner of the IP asset.
    function ownerOf(uint256 id) external view returns (address);

    /// @notice Transfers ownership of the IP asset wrapper within an IP Org.
    /// @param from The previous owner of the wrapped IP asset.
    /// @param to The new owner of the wrapped IP asset.
    /// @param id The identifier of the IP Org asset.
    function transferFrom(address from, address to, uint256 id) external;

    /// @notice Burns an IP asset wrapper within the IP Org.
    /// @dev This function is only callable by the IP Org registration module.
    /// @param id The local identifier of the IP asset within the IP Org.
    function burn(uint256 id) external;

    /// @notice Mints an IP Asset wrapper for the IP Org.
    /// @dev This function is only callable by the IP Org registration module.
    /// @param owner Address of the current owner of the local IP Org asset.
    /// @param assetType The IP Org asset type.
    /// @return id The local identifier of the minted IP Org wrapped asset.
    function mint(address owner, uint8 assetType) external returns (uint256 id);

    /// @notice Gets the current owner of the IP Org.
    /// @return The address of the IP Org owner.
    function owner() external view returns (address);

    /// @notice Returns contract-level metadata for the IP Org.
    /// @return The contract-wide URI associated with the IP Org.
    function contractURI() external view returns (string memory);

    /// @notice Returns the IP Org asset type for a given IP Org asset.
    /// @return The id associated with the IP Org asset type.
    function ipOrgAssetType(uint256 id_) external view returns (uint8);

    /// @notice Gets the global IP asset id associated with this IP Org asset.
    /// @param id_ The local id of the IP Org wrapped IP asset.
    /// @return The global identifier of the IP asset.
    function ipAssetId(uint256 id_) external returns (uint256);
}
