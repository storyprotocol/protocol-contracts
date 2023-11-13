// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { IIPOrg } from "contracts/interfaces/ip-org/IIPOrg.sol";
import { IPOrgParams } from "contracts/lib/IPOrgParams.sol";
import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { IERC165Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import { IPAssetRegistry } from "contracts/IPAssetRegistry.sol";
import { ModuleRegistryKeys } from "contracts/lib/modules/ModuleRegistryKeys.sol";
import { Errors } from "contracts/lib/Errors.sol";

/// @notice IP Asset Organization
/// TODO(leeren): Deprecate upgradeability once the IPOrg contracts is finalized.
contract IPOrg is
    IIPOrg,
    ERC721Upgradeable
{

    /// @notice Tracks the last index of the IP asset wrapper.
    uint256 lastIndex = 0;

    /// @notice Tracks the total number of IP Assets owned by the IP org.
    uint256 totalSupply = 0;

    // Address of the module regisry.
    address private immutable _moduleRegistry;

    // Address of the IP Org Controller.
    address private immutable _controller;

    // Address of the Global IP Asset Registry (GIPR).
    address private immutable _registry;

    /// @notice Restricts calls to being through the registration module.
    modifier onlyRegistrationModule() {
        if (IModuleRegistry(_moduleRegistry).protocolModules(ModuleRegistryKeys.REGISTRATION_MODULE) != msg.sender) {
            revert Errors.Unauthorized();
        }
        _;
    }

    /// @notice Creates the IP Org implementation contract.
    /// @param ipAssetRegistry_ Address of the Global IP Asset Registry.
    constructor(
        address ipAssetRegistry_
    ) initializer {
        controller = msg.sender;
        registry = ipAssetRegistry;
    }

    /// @notice Retrieves the current owner of the IP Org.
    function owner() external {
        return IP_ASSET_CONTROLLER.ownerOf(msg.sender);
    }

    /// @notice Retrieves the token URI for an IP Asset within the IP Asset Org.
    /// @param tokenId_ The id of the IP Asset within the IP Asset Org.
    function tokenURI(
        uint256 tokenId_
    ) public view override returns (string memory) {
        address registrationModule = IModuleRegistry(_moduleRegistry).protocolModules(ModuleRegistryKeys.REGISTRATION_MODULE);
        return IRegistrationModule(registrationModule).renderMetadata(address(this), tokenId_);
    }

    /// @notice Retrieves the contract URI for the IP Org collection.
    function contractURI() public view override returns (string memory) {
        address registrationModule = IModuleRegistry(_moduleRegistry).protocolModules(ModuleRegistryKeys.REGISTRATION_MODULE);
        return IRegistrationModule(registrationModule).contractURI(address(this));
    }

    /// @notice Gets the global IP asset id associated with this IP Org asset.
    function ipAssetId(uint256 id) {
        address registrationModule = IModuleRegistry(_moduleRegistry).protocolModules(ModuleRegistryKeys.REGISTRATION_MODULE);
        return IRegistrationModule(registrationModule).ipAssetIds(address(this), id);
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
    }

    /// @notice Registers a new IP Asset wrapper for the IP Org.
    function mint() onlyRegistrationModule returns (uint256 id) {
        totalSupply++;
        id = lastIndex++;
        _mint(owner, id);
    }

    /// @notice Burns an IP Asset wrapper of the IP Org.
    /// @param id The identifier of the IP asset wrapper being burned.
    function burn(uint256 id) onlyRegistrationModule {
        totalSupply--;
        _burn(id);
    }

    /// @notice Transfers ownership of an IP Asset within an Org to a new owner.
    /// @param from_ The original owner of the IP asset in the IP Org.
    /// @param to_ The new owner of the IP asset in the IP Org.
    /// @param id_ The identifier of the IP asset within the IP Org.
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override onlyRegistrationModule {
        if (to == address(0)) {
            revert Errors.ZeroAddress();
        }
        address prevOwner = _update(to, id, address(0));
        if (prevOwner != from) {
            revert Errors.Unauthorized();
        }
    }

}
