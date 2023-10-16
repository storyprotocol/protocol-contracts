// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { Clones } from '@openzeppelin/contracts/proxy/Clones.sol';
import { IPAsset } from "contracts/lib/IPAsset.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { AccessControlledUpgradeable } from "./access-control/AccessControlledUpgradeable.sol";
import { LicenseRegistry } from "contracts/modules/licensing/LicenseRegistry.sol";
import { IVersioned } from "contracts/interfaces/utils/IVersioned.sol";
import { IIPAssetGroup } from "contracts/interfaces/ip-assets/IIPAssetGroup.sol";
import { IPAssetGroup } from "contracts/ip-assets/IPAssetGroup.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

contract IPAssetController is
    UUPSUpgradeable,
    IVersioned,
    AccessControlledUpgradeable,
    ERC721Upgradeable
{

    address public immutable IP_ASSET_GROUP_IMPL = address(new IPAssetGroup());

    event IPAssetGroupRegistered(
        address owner,
        uint256 id,
        address ipAssetRegistryForId,
        string name,
        string symbol,
        string tokenURI
    );

    /// @custom:storage-location erc7201:story-protocol.franchise-registry.storage
    struct IPAssetControllerStorage {
        uint256 franchiseIds;
        /// IPAssetGroup id => IPAssetGroup address
        mapping(uint256 => address) ipAssetGroups;
        mapping(uint256 => string) tokenURIs;
    }

    // keccak256(bytes.concat(bytes32(uint256(keccak256("story-protocol.franchise-registry.storage")) - 1)))
    bytes32 private constant _STORAGE_LOCATION =
        0x5648324915b730d22cca7279385130ad43fd4829d795fb20e9ab398bfe537e8f;
    uint256 public constant PROTOCOL_ROOT_ID = 0;
    address public constant PROTOCOL_ROOT_ADDRESS = address(0);
    string private constant _VERSION = "0.1.0";

    function registerIPAssetGroup(
        IPAsset.RegisterIPAssetGroupParams calldata params_
    ) external returns (uint256, address) {
        IPAssetControllerStorage storage $ = _getIPAssetControllerStorage();
        uint256 nextId = ++$.franchiseIds;
        address ipAssetGroup = Clones.clone(IP_ASSET_GROUP_IMPL);
        IPAssetGroup(ipAssetGroup).initialize(IPAsset.InitIPAssetGroupParams({
            ipAssetController: address(this),
            franchiseId: nextId,
            name: params_.name,
            symbol: params_.symbol,
            description: params_.description,
            licensingModule: params_.licensingModule,
            collectModule: params_.collectModule
        }));
        LicenseRegistry licenseRegistry = new LicenseRegistry(
            ipAssetGroup,
            string.concat("Licenses for ", params_.name),
            string.concat("sl", params_.symbol)
        );
        IPAssetGroup(ipAssetGroup).setLicenseRegistry(address(licenseRegistry));
        $.ipAssetGroups[nextId] = ipAssetGroup;
        $.tokenURIs[nextId] = params_.tokenURI;
        _safeMint(msg.sender, nextId);

        emit IPAssetGroupRegistered(
            msg.sender,
            nextId,
            ipAssetGroup,
            params_.name,
            params_.symbol,
            params_.tokenURI
        );

        return (nextId, ipAssetGroup);
    }

    /// @notice checks if an address is a valid SP IPAssetGroup.
    /// @param ipAssetRegistry_ the address to check
    /// @return true if it's a valid SP IPAssetGroup, false otherwise
    function isIpAssetRegistry(
        address ipAssetRegistry_
    ) external view returns (bool) {
        try IIPAssetGroup(ipAssetRegistry_).franchiseId() returns (
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
        IPAssetControllerStorage storage $ = _getIPAssetControllerStorage();
        return $.ipAssetGroups[franchiseId_];
    }

    function tokenURI(
        uint256 tokenId_
    ) public view virtual override returns (string memory) {
        _requireMinted(tokenId_);
        IPAssetControllerStorage storage $ = _getIPAssetControllerStorage();
        return $.tokenURIs[tokenId_];
    }

    function _authorizeUpgrade(
        address newImplementation_
    ) internal virtual override onlyRole(AccessControl.UPGRADER_ROLE) {}

    function _getIPAssetControllerStorage()
        private
        pure
        returns (IPAssetControllerStorage storage $)
    {
        assembly {
            $.slot := _STORAGE_LOCATION
        }
    }
}
