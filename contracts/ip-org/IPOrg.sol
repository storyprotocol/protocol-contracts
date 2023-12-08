// SPDX-License-Identifier: UNLICENSED
// See https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.19;

import { IPOrgController } from "contracts/ip-org/IPOrgController.sol";
import { IIPOrg } from "contracts/interfaces/ip-org/IIPOrg.sol";
import { IModuleRegistry } from "contracts/interfaces/modules/IModuleRegistry.sol";
import { IRegistrationModule } from "contracts/interfaces/modules/registration/IRegistrationModule.sol";
import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { REGISTRATION_MODULE_KEY } from "contracts/lib/modules/Module.sol";
import { Errors } from "contracts/lib/Errors.sol";

/// @title IP Organization Contract
/// @notice An IP Org represents a collection of IP Assets governed under a single
///         administrative entity. It serves both as an org-branded NFT wrapper of
///         the IP Asset group and as a conduit used by the IP registration module
///         for transferring IP ownership and configuring its IP-related metadata.
///         Crations of new IP Orgs happen through the IP Org Controller contract.
contract IPOrg is IIPOrg, ERC721Upgradeable {
    /// @notice Tracks the last index of the IP asset wrapper.
    uint256 public lastIndex;

    /// @notice Tracks the total number of IP Assets owned by the IP org.
    uint256 public totalSupply;

    // Address of the module registry.
    IModuleRegistry public immutable MODULE_REGISTRY;

    // Address of the IP Org Controller.
    address public immutable CONTROLLER;

    /// @notice Tracks the IP asset types associated with the each IP asset wrapper.
    mapping(uint256 => uint8) private _ipOrgAssetTypes;

    /// @notice Restricts calls to being through the registration module.
    modifier onlyRegistrationModule() {
        if (address(MODULE_REGISTRY.protocolModule(REGISTRATION_MODULE_KEY)) != msg.sender) {
            revert Errors.Unauthorized();
        }
        _;
    }

    /// @notice Creates the IP Org implementation contract.
    /// @param controller_ Address of the IP Org controller.
    /// @param moduleRegistry_ Address of the IP asset module registry.
    constructor(address controller_, address moduleRegistry_) initializer {
        CONTROLLER = controller_;
        MODULE_REGISTRY = IModuleRegistry(moduleRegistry_);
    }

    /// @notice Retrieves the current owner of the IP Org.
    function owner() external view returns (address) {
        return IPOrgController(CONTROLLER).ownerOf(address(this));
    }

    /// @notice Gets the current owner of an IP asset within the IP Org.
    function ownerOf(uint256 id) public view override(IIPOrg, ERC721Upgradeable) returns (address) {
        return super.ownerOf(id);
    }

    /// @notice Retrieves the token URI for an IP Asset within the IP Asset Org.
    /// @param tokenId_ The id of the IP Asset within the IP Asset Org.
    function tokenURI(uint256 tokenId_) public view override returns (string memory) {
        address registrationModule = address(IModuleRegistry(MODULE_REGISTRY).protocolModule(REGISTRATION_MODULE_KEY));
        return IRegistrationModule(registrationModule).tokenURI(address(this), tokenId_, ipOrgAssetType(tokenId_));
    }

    /// @notice Retrieves the contract URI for the IP Org collection.
    function contractURI() public view override returns (string memory) {
        address registrationModule = address(IModuleRegistry(MODULE_REGISTRY).protocolModule(REGISTRATION_MODULE_KEY));
        return IRegistrationModule(registrationModule).contractURI(address(this));
    }

    /// @notice Gets the global IP asset id associated with this IP Org asset.
    /// @param id_ The local id of the IP Org wrapped IP asset.
    /// @return The global identifier of the IP asset.
    function ipAssetId(uint256 id_) public returns (uint256) {
        address registrationModule = address(MODULE_REGISTRY.protocolModule(REGISTRATION_MODULE_KEY));
        return IRegistrationModule(registrationModule).ipAssetId(address(this), id_);
    }

    /// @notice Initializes an IP Org.
    /// @param name_ Name to assign to the IP Org.
    /// @param symbol_ Symbol to assign to the IP Org.
    function initialize(string calldata name_, string calldata symbol_) public initializer {
        if (msg.sender != CONTROLLER) {
            revert Errors.Unauthorized();
        }

        __ERC721_init(name_, symbol_);
    }

    /// @notice Registers a new IP Asset wrapper for the IP Org.
    function mint(address owner_, uint8 assetType_) public onlyRegistrationModule returns (uint256 id) {
        totalSupply++;
        id = ++lastIndex;
        _ipOrgAssetTypes[id] = assetType_;
        _mint(owner_, id);
    }

    /// @notice Burns an IP Asset wrapper of the IP Org.
    /// @param id The identifier of the IP asset wrapper being burned.
    function burn(uint256 id) public onlyRegistrationModule {
        totalSupply--;
        _burn(id);
    }

    /// @notice Transfers ownership of an IP Asset within an Org to a new owner.
    /// @param from_ The original owner of the IP asset in the IP Org.
    /// @param to_ The new owner of the IP asset in the IP Org.
    /// @param id_ The identifier of the IP asset within the IP Org.
    function transferFrom(
        address from_,
        address to_,
        uint256 id_
    ) public override(IIPOrg, ERC721Upgradeable) onlyRegistrationModule {
        _transfer(from_, to_, id_);
    }

    /// @notice Returns the IP Org asset type for a given IP Org asset.
    /// @param id_ The identifier of the IP asset within the IP Org.
    function ipOrgAssetType(uint256 id_) public view returns (uint8) {
        if (!_exists(id_)) {
            revert Errors.IPOrg_IdDoesNotExist();
        }
        return _ipOrgAssetTypes[id_];
    }
}
