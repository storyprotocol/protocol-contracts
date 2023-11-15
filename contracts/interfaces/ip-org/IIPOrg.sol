// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { IPAsset } from "contracts/lib/IPAsset.sol";

/// @notice IP Org Interface
interface IIPOrg {

    /// @notice Returns the current owner of the IP asset within th IP Org.
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
    /// @return id The local identifier of the minted IP Org wrapped asset.
    function mint(address owner) external returns (uint256 id);

    /// @notice Gets the current owner of the IP Org.
    function owner() external view returns (address);

    /// @notice Returns contract-level metadata for the IP Org.
    function contractURI() external view returns (string memory);

}
