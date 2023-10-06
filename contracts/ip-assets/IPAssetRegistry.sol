// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IIPAssetRegistry } from "contracts/interfaces/ip-assets/IIPAssetRegistry.sol";
import { ICollectModule } from "contracts/interfaces/modules/collect/ICollectModule.sol";
import { LibIPAssetID } from "./LibIPAssetID.sol";
import { ZeroAmount, ZeroAddress } from "../errors/General.sol";
import { IPAsset } from "contracts/IPAsset.sol";
import { InitCollectParams } from "contracts/lib/CollectModuleStructs.sol";
import { IIPAssetEventEmitter } from "contracts/interfaces/ip-assets/events/IIPAssetEventEmitter.sol";
import { IPAssetDataManager } from "./storage/IPAssetDataManager.sol";
import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { IERC165Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import { MulticallUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import { RightsManager } from "../modules/licensing/RightsManager.sol";
import { ILicensingModule } from "contracts/interfaces/modules/licensing/ILicensingModule.sol";

contract IPAssetRegistry is
    IPAssetDataManager,
    RightsManager,
    MulticallUpgradeable
{
    error IdOverBounds();
    error LicensingNotConfigured();

    /// @custom:storage-location erc7201:story-protocol.ip-assets-registry.storage
    struct IPAssetRegistryStorage {
        /// @dev ipAssetId => id counter
        mapping(IPAsset => uint256) ids;
        string description;
        uint256 franchiseId;
    }

    IIPAssetEventEmitter public immutable EVENT_EMITTER;
    ILicensingModule public immutable LICENSING_MODULE;
    ICollectModule public immutable COLLECT_MODULE;

    // keccak256(bytes.concat(bytes32(uint256(keccak256("story-protocol.ip-assets-registry.storage")) - 1)))
    bytes32 private constant _STORAGE_LOCATION =
        0x1a0b8fa444ff575656111a4368b8e6a743b70cbf31ffb9ee2c7afe1983f0e378;
    string private constant _VERSION = "0.1.0";
    uint256 private constant _ROOT_IP_ASSET = 0;

    constructor(
        address eventEmitter_,
        address licensingModule_,
        address franchiseRegistry_,
        address collectModule_
    ) RightsManager(franchiseRegistry_) {
        // TODO: should Franchise owner be able to change this?
        if (eventEmitter_ == address(0)) revert ZeroAddress();
        EVENT_EMITTER = IIPAssetEventEmitter(eventEmitter_);
        if (licensingModule_ == address(0)) revert ZeroAddress();
        LICENSING_MODULE = ILicensingModule(licensingModule_);
        if (collectModule_ == address(0)) revert ZeroAddress();
        COLLECT_MODULE = ICollectModule(collectModule_);
        _disableInitializers();
    }

    function initialize(
        uint256 franchiseId_,
        string calldata name_,
        string calldata symbol_,
        string calldata description_
    ) public initializer {
        __RightsManager_init(name_, symbol_);
        __Multicall_init();
        if (franchiseId_ == 0) revert ZeroAmount();
        IPAssetRegistryStorage storage $ = _getIPAssetRegistryStorage();
        $.franchiseId = franchiseId_;
        $.description = description_;
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

    /// Creates a new IPAsset, and assigns licenses (rights) to it, according to the Franchise
    /// config in LicensingModule.
    /// A Non commercial license is always assigned, and if the IPAsset is a root IPAsset,
    /// a commercial license may also be assigned.
    /// @dev reverts if LicensingModule is not configured for the Franchise.
    /// Logs to IPAssetEventEmitter, common contract for all IPAsset registries.
    /// @param ipAssetType_ the type of IPAsset to create
    /// @param name_ IPAsset name
    /// @param description_ short description of the IPAsset
    /// @param mediaUrl_ url to the IPAsset media and metadata
    /// @param to_ holder of the IPAsset (and thus the licenses)
    /// @param parentIpAssetId_ 0 if this is a root IPAsset, if it is a derivative, set the parent IPAsset id
    /// @param collectData_ Additional data passed for collect module initialization
    /// @return the created IPAsset id
    function createIpAsset(
        IPAsset ipAssetType_,
        string calldata name_,
        string calldata description_,
        string calldata mediaUrl_,
        address to_,
        uint256 parentIpAssetId_,
        bytes calldata collectData_
    ) public returns (uint256) {
        if (ipAssetType_ == IPAsset.UNDEFINED) revert InvalidBlockType();
        uint256 ipAssetId = _mintBlock(to_, ipAssetType_);
        _writeIPAsset(ipAssetId, name_, description_, mediaUrl_);
        IPAssetRegistryStorage storage $ = _getIPAssetRegistryStorage();
        uint256 _franchiseId = $.franchiseId;
        EVENT_EMITTER.emitIpAssetCreation(_franchiseId, ipAssetId);
        // Non commercial
        ILicensingModule.FranchiseConfig memory config = LICENSING_MODULE
            .getFranchiseConfig(_franchiseId);
        if (config.revoker == address(0)) revert LicensingNotConfigured();
        _setNonCommercialRights(
            ipAssetId,
            parentIpAssetId_,
            to_,
            config.revoker,
            config.nonCommercialConfig,
            config.nonCommercialTerms
        );
        // If non derivative IpAsset, then franchise config may dictate commercial rights
        // Derivative works do not have commercial rights unless a deal with the relevant licensor is made
        if (config.rootIpAssetHasCommercialRights && parentIpAssetId_ == 0) {
            // Commercial
            _setCommercialRights(
                ipAssetId,
                _ROOT_IP_ASSET,
                to_,
                config.revoker,
                config.commercialLicenseUri,
                config.commercialConfig,
                config.commercialTerms
            );
        }
        // TODO: Add collect NFT impl and data overrides
        COLLECT_MODULE.initCollect(
            InitCollectParams({
                franchiseId: _franchiseId,
                ipAssetId: ipAssetId,
                collectNftImpl: address(0), // Default collect module NFT impl
                data: collectData_
            })
        );
        return ipAssetId;
    }

    /// Sets the non commercial rights for an IPAsset, with terms from the Franchise config in LicensingModule.
    /// If no parent asset id is provided, the root IPAsset id is used if it exists in the Franchise config.
    /// @param ipAssetId_ the IPAsset id
    /// @param parentIpAssetId_ in case this is a derivative IPAsset, set the parent IPAsset id, 0 otherwise
    /// @param holder_ of the IPAsset and licenses
    /// @param revoker_ of the license. Can't be zero or changed later
    /// @param config_ Franchise config
    /// @param terms_ for the license to be active
    function _setNonCommercialRights(
        uint256 ipAssetId_,
        uint256 parentIpAssetId_,
        address holder_,
        address revoker_,
        ILicensingModule.IpAssetConfig memory config_,
        TermsProcessorConfig memory terms_
    ) internal {
        uint256 parentLicenseId = parentIpAssetId_ == 0
            ? config_.franchiseRootLicenseId
            : getLicenseIdByTokenId(parentIpAssetId_, false);
        _createLicense(
            ipAssetId_,
            parentLicenseId,
            holder_,
            LICENSING_MODULE.getNonCommercialLicenseURI(),
            revoker_,
            false,
            config_.canSublicense,
            terms_,
            false
        );
    }

    /// Sets the commercial rights for an IPAsset, with terms from the Franchise config in LicensingModule.
    /// If no parent asset id is provided, the root IPAsset id is used if it exists in the Franchise config.
    /// @param ipAssetId_ the IPAsset id
    /// @param parentIpAssetId_ in case this is a derivative IPAsset, set the parent IPAsset id, 0 otherwise
    /// @param holder_ of the IPAsset and licenses
    /// @param revoker_ of the license. Can't be zero or changed later
    /// @param config_ Franchise config
    /// @param terms_ for the license to be active
    function _setCommercialRights(
        uint256 ipAssetId_,
        uint256 parentIpAssetId_,
        address holder_,
        address revoker_,
        string memory licenseUri_,
        ILicensingModule.IpAssetConfig memory config_,
        TermsProcessorConfig memory terms_
    ) internal {
        uint256 parentLicenseId = parentIpAssetId_ == _ROOT_IP_ASSET
            ? config_.franchiseRootLicenseId
            : getLicenseIdByTokenId(parentIpAssetId_, true);
        _createLicense(
            ipAssetId_,
            parentLicenseId,
            holder_,
            licenseUri_,
            revoker_,
            true,
            config_.canSublicense,
            terms_,
            false
        );
    }

    /// mints the IPAsset block, and assigns the next id to it.
    /// @param to_ holder
    /// @param ipAssetId_ ip asset type
    function _mintBlock(
        address to_,
        IPAsset ipAssetId_
    ) private returns (uint256) {
        uint256 nextId = currentIdFor(ipAssetId_) + 1;
        if (nextId > LibIPAssetID._lastId(ipAssetId_)) revert IdOverBounds();
        IPAssetRegistryStorage storage $ = _getIPAssetRegistryStorage();
        $.ids[ipAssetId_] = nextId;
        _safeMint(to_, nextId);
        return nextId;
    }

    function currentIdFor(IPAsset ipAssetId_) public view returns (uint256) {
        IPAssetRegistryStorage storage $ = _getIPAssetRegistryStorage();
        uint256 currentId = $.ids[ipAssetId_];
        if (currentId == 0) {
            return LibIPAssetID._zeroId(ipAssetId_);
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
        uint256 tokenId_
    ) public view override returns (string memory) {
        // TODO: should this reference the license too?
        return readIPAsset(tokenId_).mediaUrl;
    }

    function supportsInterface(
        bytes4 interfaceId_
    )
        public
        view
        virtual
        override(ERC721Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId_ == type(IIPAssetRegistry).interfaceId ||
            super.supportsInterface(interfaceId_);
    }
}
