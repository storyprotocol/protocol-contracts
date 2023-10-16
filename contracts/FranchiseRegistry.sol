// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { Errors } from "contracts/lib/Errors.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { IPAssetRegistryFactory } from "./ip-assets/IPAssetRegistryFactory.sol";
import { AccessControlledUpgradeable } from "./access-control/AccessControlledUpgradeable.sol";
import { IVersioned } from "contracts/interfaces/utils/IVersioned.sol";
import { IIPAssetRegistry } from "contracts/interfaces/ip-assets/IIPAssetRegistry.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

contract FranchiseRegistry is
    UUPSUpgradeable,
    IVersioned,
    AccessControlledUpgradeable,
    ERC721Upgradeable
{
    event FranchiseRegistered(
        address owner,
        uint256 id,
        address ipAssetRegistryForId,
        string name,
        string symbol,
        string tokenURI
    );

    /// TODO: Add franchise interface and place this in separate lib
    struct FranchiseCreationParams {
        string name;
        string symbol;
        string description;
        string tokenURI;
    }

    /// @custom:storage-location erc7201:story-protocol.franchise-registry.storage
    struct FranchiseStorage {
        uint256 franchiseIds;
        /// Franchise id => IPAssetRegistry address
        mapping(uint256 => address) ipAssetRegistries;
        mapping(uint256 => string) tokenURIs;
    }

    IPAssetRegistryFactory public immutable FACTORY;
    // keccak256(bytes.concat(bytes32(uint256(keccak256("story-protocol.franchise-registry.storage")) - 1)))
    bytes32 private constant _STORAGE_LOCATION =
        0x5648324915b730d22cca7279385130ad43fd4829d795fb20e9ab398bfe537e8f;
    uint256 public constant PROTOCOL_ROOT_ID = 0;
    address public constant PROTOCOL_ROOT_ADDRESS = address(0);
    string private constant _VERSION = "0.1.0";

    constructor(address factory_) {
        if (factory_ == address(0)) revert Errors.ZeroAddress();
        FACTORY = IPAssetRegistryFactory(factory_);
        _disableInitializers();
    }

    function registerFranchise(
        FranchiseCreationParams calldata params_
    ) external returns (uint256, address) {
        FranchiseStorage storage $ = _getFranchiseStorage();
        uint256 nextId = ++$.franchiseIds;
        address ipAssetRegistry = FACTORY.createFranchiseIpAssets(
            nextId,
            params_.name,
            params_.symbol,
            params_.description
        );
        $.ipAssetRegistries[nextId] = ipAssetRegistry;
        $.tokenURIs[nextId] = params_.tokenURI;
        _safeMint(msg.sender, nextId);
        // TODO: set licensing restrictions per franchise, maybe grant commercial root license to the franchise NFT

        emit FranchiseRegistered(
            msg.sender,
            nextId,
            ipAssetRegistry,
            params_.name,
            params_.symbol,
            params_.tokenURI
        );

        return (nextId, ipAssetRegistry);
    }

    /// @notice checks if an address is a valid SP IPAssetRegistry.
    /// @param ipAssetRegistry_ the address to check
    /// @return true if it's a valid SP IPAssetRegistry, false otherwise
    function isIpAssetRegistry(
        address ipAssetRegistry_
    ) external view returns (bool) {
        try IIPAssetRegistry(ipAssetRegistry_).franchiseId() returns (
            uint256 franchiseId
        ) {
            return ipAssetRegistryForId(franchiseId) == ipAssetRegistry_;
        } catch {
            return false;
        }
    }

    function version() external pure override returns (string memory) {
        return _VERSION;
    }

    function initialize(address accessControl_) public initializer {
        __UUPSUpgradeable_init();
        __AccessControlledUpgradeable_init(accessControl_);
        __ERC721_init("Story Protocol", "SP");
    }

    function ipAssetRegistryForId(
        uint256 franchiseId_
    ) public view returns (address) {
        FranchiseStorage storage $ = _getFranchiseStorage();
        return $.ipAssetRegistries[franchiseId_];
    }

    function tokenURI(
        uint256 tokenId_
    ) public view virtual override returns (string memory) {
        _requireMinted(tokenId_);
        FranchiseStorage storage $ = _getFranchiseStorage();
        return $.tokenURIs[tokenId_];
    }

    function _authorizeUpgrade(
        address newImplementation_
    ) internal virtual override onlyRole(AccessControl.UPGRADER_ROLE) {}

    function _getFranchiseStorage()
        private
        pure
        returns (FranchiseStorage storage $)
    {
        assembly {
            $.slot := _STORAGE_LOCATION
        }
    }
}
