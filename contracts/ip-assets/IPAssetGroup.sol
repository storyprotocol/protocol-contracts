// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IIPAssetGroup } from "contracts/interfaces/ip-assets/IIPAssetGroup.sol";
import { ICollectModule } from "contracts/interfaces/modules/collect/ICollectModule.sol";
import { IPAsset } from "contracts/lib/IPAsset.sol";
import { IIPAssetEventEmitter } from "contracts/interfaces/ip-assets/events/IIPAssetEventEmitter.sol";
import { IPAssetGroupDataManager } from "./storage/IPAssetGroupDataManager.sol";
import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { IERC165Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import { MulticallUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import { RightsManager } from "../modules/licensing/RightsManager.sol";
import { ILicensingModule } from "contracts/interfaces/modules/licensing/ILicensingModule.sol";
import { Collect } from "contracts/lib/modules/Collect.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { Licensing } from "contracts/lib/modules/Licensing.sol";

contract IPAssetGroup is
    IPAssetGroupDataManager,
    RightsManager,
    MulticallUpgradeable
{

    /// @custom:storage-location erc7201:story-protocol.ip-assets-registry.storage
    struct IPAssetGroupStorage {
        /// @dev ipAssetId => id counter
        mapping(IPAsset.IPAssetType => uint256) ids;
        string description;
        uint256 franchiseId;
    }

    ILicensingModule public LICENSING_MODULE;
    ICollectModule public COLLECT_MODULE;

    // keccak256(bytes.concat(bytes32(uint256(keccak256("story-protocol.ip-assets-registry.storage")) - 1)))
    bytes32 private constant _STORAGE_LOCATION =
        0x1a0b8fa444ff575656111a4368b8e6a743b70cbf31ffb9ee2c7afe1983f0e378;
    string private constant _VERSION = "0.1.0";
    uint256 private constant _ROOT_IP_ASSET = 0;

    function initialize(IPAsset.InitIPAssetGroupParams memory params_) public initializer {

        __RightsManager_init(params_.ipAssetController, params_.name, params_.symbol);
        __Multicall_init();

        if (params_.licensingModule == address(0)) revert Errors.ZeroAddress();
        LICENSING_MODULE = ILicensingModule(params_.licensingModule);

        if (params_.collectModule == address(0)) revert Errors.ZeroAddress();
        COLLECT_MODULE = ICollectModule(params_.collectModule);

        if (params_.franchiseId == 0) revert Errors.ZeroAmount();
        IPAssetGroupStorage storage $ = _getIPAssetGroupStorage();
        $.franchiseId = params_.franchiseId;
        $.description = params_.description;
    }


    function description() external view returns (string memory) {
        IPAssetGroupStorage storage $ = _getIPAssetGroupStorage();
        return $.description;
    }

    function franchiseId() external view returns (uint256) {
        IPAssetGroupStorage storage $ = _getIPAssetGroupStorage();
        return $.franchiseId;
    }

    function version() external pure virtual returns (string memory) {
        return _VERSION;
    }

    /// Creates a new IPAsset, and assigns licenses (rights) to it, according to the IPAssetGroup
    /// config in LicensingModule.
    /// A Non commercial license is always assigned, and if the IPAsset is a root IPAsset,
    /// a commercial license may also be assigned.
    /// @dev reverts if LicensingModule is not configured for the IPAssetGroup.
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
        IPAsset.IPAssetType ipAssetType_,
        string calldata name_,
        string calldata description_,
        string calldata mediaUrl_,
        address to_,
        uint256 parentIpAssetId_,
        bytes calldata collectData_
    ) public returns (uint256) {
        if (ipAssetType_ == IPAsset.IPAssetType.UNDEFINED) revert Errors.IPAsset_InvalidType(IPAsset.IPAssetType.UNDEFINED);
        uint256 ipAssetId = _mintBlock(to_, ipAssetType_);
        _writeIPAsset(ipAssetId, name_, description_, mediaUrl_);
        IPAssetGroupStorage storage $ = _getIPAssetGroupStorage();

        // Non commercial
        Licensing.IPAssetGroupConfig memory config = LICENSING_MODULE
            .getIPAssetGroupConfig($.franchiseId);
        if (config.revoker == address(0)) revert Errors.IPAssetGroup_LicensingNotConfigured();
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
            Collect.InitCollectParams({
                franchiseId: $.franchiseId,
                ipAssetId: ipAssetId,
                collectNftImpl: address(0), // Default collect module NFT impl
                data: collectData_
            })
        );
        return ipAssetId;
    }

    function tokenURI(
        uint256 tokenId_
    ) public view override returns (string memory) {
        // TODO: should this reference the license too?
        return readIPAsset(tokenId_).mediaUrl;
    }

    function supportsInterface(
        bytes4 interfaceId_
    ) public
    view
    virtual
    override(ERC721Upgradeable, IERC165Upgradeable)
    returns (bool)
    {
        return
            interfaceId_ == type(IIPAssetGroup).interfaceId ||
            super.supportsInterface(interfaceId_);
    }

    /// Sets the non commercial rights for an IPAsset, with terms from the IPAssetGroup config in LicensingModule.
    /// If no parent asset id is provided, the root IPAsset id is used if it exists in the IPAssetGroup config.
    /// @param ipAssetId_ the IPAsset id
    /// @param parentIpAssetId_ in case this is a derivative IPAsset, set the parent IPAsset id, 0 otherwise
    /// @param holder_ of the IPAsset and licenses
    /// @param revoker_ of the license. Can't be zero or changed later
    /// @param config_ IPAssetGroup config
    /// @param terms_ for the license to be active
    function _setNonCommercialRights(
        uint256 ipAssetId_,
        uint256 parentIpAssetId_,
        address holder_,
        address revoker_,
        Licensing.IpAssetConfig memory config_,
        Licensing.TermsProcessorConfig memory terms_
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

    /// Sets the commercial rights for an IPAsset, with terms from the IPAssetGroup config in LicensingModule.
    /// If no parent asset id is provided, the root IPAsset id is used if it exists in the IPAssetGroup config.
    /// @param ipAssetId_ the IPAsset id
    /// @param parentIpAssetId_ in case this is a derivative IPAsset, set the parent IPAsset id, 0 otherwise
    /// @param holder_ of the IPAsset and licenses
    /// @param revoker_ of the license. Can't be zero or changed later
    /// @param config_ IPAssetGroup config
    /// @param terms_ for the license to be active
    function _setCommercialRights(
        uint256 ipAssetId_,
        uint256 parentIpAssetId_,
        address holder_,
        address revoker_,
        string memory licenseUri_,
        Licensing.IpAssetConfig memory config_,
        Licensing.TermsProcessorConfig memory terms_
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
        IPAsset.IPAssetType ipAssetId_
    ) private returns (uint256) {
        uint256 nextId = currentIdFor(ipAssetId_) + 1;
        if (nextId > IPAsset._lastId(ipAssetId_)) revert Errors.IPAssetGroup_IdOverBounds();
        IPAssetGroupStorage storage $ = _getIPAssetGroupStorage();
        $.ids[ipAssetId_] = nextId;
        _safeMint(to_, nextId);
        return nextId;
    }

    function currentIdFor(IPAsset.IPAssetType ipAssetId_) public view returns (uint256) {
        IPAssetGroupStorage storage $ = _getIPAssetGroupStorage();
        uint256 currentId = $.ids[ipAssetId_];
        if (currentId == 0) {
            return IPAsset._zeroId(ipAssetId_);
        } else {
            return currentId;
        }
    }

    function _getIPAssetGroupStorage()
        private
        pure
        returns (IPAssetGroupStorage storage $)
    {
        assembly {
            $.slot := _STORAGE_LOCATION
        }
    }
}
