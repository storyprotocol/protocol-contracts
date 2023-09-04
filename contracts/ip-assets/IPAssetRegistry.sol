// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IIPAssetRegistry } from "./IIPAssetRegistry.sol";
import { LibIPAssetId } from "./LibIPAssetId.sol";
import { Unauthorized, ZeroAmount, ZeroAddress } from "../errors/General.sol";
import { IPAsset } from "contracts/IPAsset.sol";
import { IIPAssetEventEmitter } from "./events/IIPAssetEventEmitter.sol";
import { IPAssetDataManager } from "./storage/IPAssetDataManager.sol";
import { ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { IERC165Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import { MulticallUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import { RightsManager } from "../modules/licensing/RightsManager.sol";
import { ILicensingModule } from "../modules/licensing/ILicensingModule.sol";

contract IPAssetRegistry is
    IPAssetDataManager,
    RightsManager,
    MulticallUpgradeable
{
    error IdOverBounds();
    error LicensingNotConfigured();

    /// @custom:storage-location erc7201:story-protocol.ip-assets-registry.storage
    struct IPAssetRegistryStorage {
        /// @dev IPAssetId => id counter
        mapping(IPAsset => uint256) ids;
        string description;
        uint256 franchiseId;
    }

    IIPAssetEventEmitter public immutable EVENT_EMITTER;
    ILicensingModule public immutable LICENSING_MODULE;
    // keccak256(bytes.concat(bytes32(uint256(keccak256("story-protocol.ip-assets-registry.storage")) - 1)))
    bytes32 private constant _STORAGE_LOCATION =
        0x1a0b8fa444ff575656111a4368b8e6a743b70cbf31ffb9ee2c7afe1983f0e378;
    string private constant _VERSION = "0.1.0";

    constructor(address _eventEmitter, address _licensingModule, address _franchiseRegistry) RightsManager(_franchiseRegistry) {
        // TODO: should Franchise owner be able to change this?
        if (_eventEmitter == address(0)) revert ZeroAddress();
        EVENT_EMITTER = IIPAssetEventEmitter(_eventEmitter);
        if (_licensingModule == address(0)) revert ZeroAddress();
        LICENSING_MODULE = ILicensingModule(_licensingModule);
        _disableInitializers();
    }

    function initialize(
        uint256 _franchiseId,
        string calldata _name,
        string calldata _symbol,
        string calldata _description
    ) public initializer {
        __RightsManager_init(_name, _symbol);
        __Multicall_init();
        if (_franchiseId == 0) revert ZeroAmount();
        IPAssetRegistryStorage storage $ = _getIPAssetRegistryStorage();
        $.franchiseId = _franchiseId;
        $.description = _description;
    }

    function _getIPAssetRegistryStorage()
        private
        pure
        returns (IPAssetRegistryStorage storage $)
    {
        assembly {
            $.slot := _STORAGE_LOCATION
        }
    }

    function version() external pure virtual returns (string memory) {
        return _VERSION;
    }

    function createIPAsset(
        IPAsset ipAssetType,
        string calldata name,
        string calldata _description,
        string calldata mediaUrl,
        address to,
        uint256 parentIpAssetId
    )
        public
        returns (uint256)
    {
        if (ipAssetType == IPAsset.UNDEFINED) revert InvalidBlockType();
        uint256 ipAssetId = _mintBlock(to, ipAssetType);
        _writeIPAsset(ipAssetId, name, _description, mediaUrl);
        IPAssetRegistryStorage storage $ = _getIPAssetRegistryStorage();
        EVENT_EMITTER.emitIPAssetCreation($.franchiseId, ipAssetId);
        
        // Non commercial
        ILicensingModule.FranchiseConfig memory config = LICENSING_MODULE.getFranchiseConfig($.franchiseId);
        if (config.revoker == address(0)) revert LicensingNotConfigured();

        _setNonCommercialRights(ipAssetId, parentIpAssetId, to, config.revoker, config.nonCommercialConfig, config.nonCommercialTerms);
        // If non derivative IpAsset, then franchise config may dictate commercial rights
        // Derivative works do not have commercial rights unless a deal with the relevant licensor is made
        if (config.rootIpAssetHasCommercialRights && parentIpAssetId == 0) {
            // Commercial
            _setCommercialRights(ipAssetId, 0, to, config.revoker, config.commercialLicenseUri, config.commercialConfig, config.commercialTerms);
        }
        
        return ipAssetId;
    }

    function _setNonCommercialRights(uint256 ipAssetId, uint256 parentIpAssetId, address holder, address revoker, ILicensingModule.IpAssetConfig memory config, TermsProcessorConfig memory terms) internal {
        uint256 parentLicenseId = parentIpAssetId == 0 ? config.franchiseRootLicenseId : getLicenseIdByTokenId(parentIpAssetId, false);
        _createLicense(
            ipAssetId,
            parentLicenseId,
            holder,
            LICENSING_MODULE.getNonCommercialLicenseURI(),
            revoker,
            false,
            config.canSublicense,
            terms,
            false
        );
    }

    function _setCommercialRights(uint256 ipAssetId, uint256 parentIpAssetId, address holder, address revoker, string memory licenseUri, ILicensingModule.IpAssetConfig memory config, TermsProcessorConfig memory terms) internal {
        uint256 parentLicenseId = parentIpAssetId == 0 ? config.franchiseRootLicenseId : getLicenseIdByTokenId(parentIpAssetId, true);
        _createLicense(
            ipAssetId,
            parentLicenseId,
            holder,
            licenseUri,
            revoker,
            true,
            config.canSublicense,
            terms,
            false
        );
    }


    function _mintBlock(address to, IPAsset sb) private returns (uint256) {
        uint256 nextId = currentIdFor(sb) + 1;
        if (nextId > LibIPAssetId._lastId(sb)) revert IdOverBounds();
        IPAssetRegistryStorage storage $ = _getIPAssetRegistryStorage();
        $.ids[sb] = nextId;
        _safeMint(to, nextId);
        return nextId;
    }

    function currentIdFor(IPAsset sb) public view returns (uint256) {
        IPAssetRegistryStorage storage $ = _getIPAssetRegistryStorage();
        uint256 currentId = $.ids[sb];
        if (currentId == 0) {
            return LibIPAssetId._zeroId(sb);
        } else {
            return currentId;
        }
    }

    function description() external view returns (string memory) {
        IPAssetRegistryStorage storage $ = _getIPAssetRegistryStorage();
        return $.description;
    }

    function franchiseId() external view returns (uint256) {
        IPAssetRegistryStorage storage $ = _getIPAssetRegistryStorage();
        return $.franchiseId;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        return readIPAsset(tokenId).mediaUrl;
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IIPAssetRegistry).interfaceId ||
            super.supportsInterface(interfaceId);
    }

}
