// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { IIPOrg } from "contracts/interfaces/ip-org/IIPOrg.sol";
import { IPOrgParams } from "contracts/lib/IPOrgParams.sol";
import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { IERC165Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import { MulticallUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import { IPAssetRegistry } from "contracts/IPAssetRegistry.sol";
import { Errors } from "contracts/lib/Errors.sol";

/// @notice IP Asset Organization
/// TODO(leeren): Deprecate upgradeability once the IPOrg contracts is finalized.
contract IPOrg is
    IIPOrg,
    ERC721Upgradeable,
    MulticallUpgradeable
{

    struct IPOrgAsset {
        uint256 ipAssetId;
        string name;
        string description;
    }
    
    /// @custom:storage-location erc7201:story-protocol.ip-asset-org.storage
    // TODO: Refactor IP asset types to be specified through the IP Asset Registry or one of its modules.
    struct IPOrgStorage {
    }

    // Address of the IP Org Controller.
    address private immutable controller;
    // Address of the Global IP Asset Registry
    address private immutable registry;

    // keccak256(bytes.concat(bytes32(uint256(keccak256("story-protocol.ip-org-registry.storage")) - 1)))
    bytes32 private constant _STORAGE_LOCATION = bytes32(uint256(keccak256("story-protocol.ip-org.storage")) - 1);

    /// @notice Creates the IP Org implementation contract.
    /// @param ipAssetRegistry_ Address of the Global IP Asset Registry.
    constructor(
        address ipAssetRegistry_
    ) initializer {
        controller = msg.sender;
        registry = ipAssetRegistry;
    }

    /// @notice Initializes an IP Org.
    /// @param name_ Name to assign to the IP Org.
    /// @param symbol_ Symbol to assign to the IP Org.
    /// @param renderer_ Renderer used for IPOrg-localized metadata of IP.
    /// @param rendererInitData_ Initialization data to pass to the renderer.
    function initialize(
        string name_,
        string symbol_,
        IIPOrgMetadataRenderer renderer_,
        bytes memory rendererInitData_
    ) public initializer {

        if (msg.sender != controller) {
            revert Errors.Unauthorized();
        }

        __ERC721_init(params_.name, params_.symbol);

        __Multicall_init();
        __Ownable_init();
    }

    function createIpAsset(IPAsset.CreateIpAssetParams calldata params_) public returns (uint256, uint256) {
        if (params_.ipAssetType == IPAsset.IPAssetType.UNDEFINED) revert Errors.IPAsset_InvalidType(IPAsset.IPAssetType.UNDEFINED);
        // TODO: Add module and other relevant configuration for registration.
        uint256 ipAssetId = REGISTRY.register(msg.sender, address(this));
        uint256 ipAssetOrgId = _mintBlock(params_.to, params_.ipAssetType);
        _writeIPAsset(ipAssetId, ipAssetOrgId, params_.name, params_.description, params_.mediaUrl);
        IPAssetOrgStorage storage $ = _getIPAssetOrgStorage();

        return (ipAssetId, ipAssetOrgId);
    }

    /// @notice Retrieves the token URI for an IP Asset within the IP Asset Org.
    /// @param tokenId_ The id of the IP Asset within the IP Asset Org.
    function tokenURI(
        uint256 tokenId_
    ) public view override returns (string memory) {
        // TODO: should this reference the license too?
        return "TODO";
    }

    /// @notice Retrieves the current owner of the IP Org.
    function owner() external {
        return IP_ASSET_CONTROLLER.ownerOf(msg.sender);
    }

    /// @dev Gets the storage associated with the IPOrg contract.
    function _getIPOrgStorage()
        private
        pure
        returns (IPOrgStorage storage $)
    {
        assembly {
            $.slot := _STORAGE_LOCATION
        }
    }
}
