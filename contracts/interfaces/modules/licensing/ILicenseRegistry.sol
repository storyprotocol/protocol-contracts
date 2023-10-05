// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";



/// @title ILicenseRegistry
/// @author Raul Martinez
/// @notice Interface for NFT tracking the ownership of tradeable Licenses emitted by a RightsManager.
interface ILicenseRegistry is IERC721 {

    function mint(address to, uint256 tokenId) external;
    function exists(uint256 tokenId) external view returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function getRightsManager() external view returns (address);

}