// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { IIPAssetOrg } from "contracts/interfaces/ip-assets/IIPAssetOrg.sol";
import { ICollectModule } from "contracts/interfaces/modules/collect/ICollectModule.sol";
import { IPAsset } from "contracts/lib/IPAsset.sol";
import { IPAssetOrgDataManager } from "./storage/IPAssetOrgDataManager.sol";
import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { IERC165Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import { MulticallUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import { RightsManager } from "../modules/licensing/RightsManager.sol";
import { IPAssetRegistry } from "contracts/IPAssetRegistry.sol";
import { ILicensingModule } from "contracts/interfaces/modules/licensing/ILicensingModule.sol";
import { Collect } from "contracts/lib/modules/Collect.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { Licensing } from "contracts/lib/modules/Licensing.sol";

/// @notice IP Asset Organization
contract IPAssetOrg is
    IPAssetOrgDataManager,
    RightsManager,
    MulticallUpgradeable,
    OwnableUpgradeable
{

    /// @custom:storage-location erc7201:story-protocol.ip-asset-org.storage
    // TODO: Refactor IP asset types to be specified through the IP Asset Registry or one of its modules.
    struct IPAssetOrgStorage {
        /// @dev ipAssetId => id counter
        mapping(IPAsset.IPAssetType => uint256) idsByType;
    }

    IPAssetRegistry public REGISTRY;
    ILicensingModule public LICENSING_MODULE;
    ICollectModule public COLLECT_MODULE;

    // keccak256(bytes.concat(bytes32(uint256(keccak256("story-protocol.ip-assets-registry.storage")) - 1)))
    bytes32 private constant _STORAGE_LOCATION = 0x1a0b8fa444ff575656111a4368b8e6a743b70cbf31ffb9ee2c7afe1983f0e378;
    string private constant _VERSION = "0.1.0";

    // TODO(ramarti): Refactor to configure IP Asset types via registry modules.
    uint256 private constant _ROOT_IP_ASSET = 0;

    function initialize(IPAsset.InitIPAssetOrgParams memory params_) public initializer {

        // TODO(ramarti) Decouple IPAssetOrg from the RightsManager and make sure to move `__ERC721_init` here.
        __RightsManager_init(address(this), params_.name, params_.symbol);

        __Multicall_init();
        __Ownable_init();
        // TODO: Weird bug does not allow OZ to specify owner in init...
        _transferOwnership(params_.owner);


        if (params_.registry == address(0)) revert Errors.ZeroAddress();
        REGISTRY = IPAssetRegistry(params_.registry);

        if (params_.licensingModule == address(0)) revert Errors.ZeroAddress();
        LICENSING_MODULE = ILicensingModule(params_.licensingModule);

        if (params_.collectModule == address(0)) revert Errors.ZeroAddress();
        COLLECT_MODULE = ICollectModule(params_.collectModule);
    }

    /// @notice Returns the current version of the IP asset org contract.
    function version() external pure virtual returns (string memory) {
        return _VERSION;
    }

    /// Creates a new IPAsset, and assigns licenses (rights) to it, according to the IPAssetOrg
    /// config in LicensingModule.
    /// A Non commercial license is always assigned, and if the IPAsset is a root IPAsset,
    /// a commercial license may also be assigned.
    /// @dev reverts if LicensingModule is not configured for the IPAssetOrg.
    /// @param params_ The parameters used for IP Asset creation.
    /// @return the created IP Asset id (and IP Asset org id).
    /// TODO(ramarti): Refactor licensing configuration to use registry asset ids instead of ip asset org ids.
    /// TODO(leeren): Deprecate returning of internal IP Asset org id once existing dependencies to it are removed.
    function createIpAsset(IPAsset.CreateIpAssetParams calldata params_) public returns (uint256, uint256) {
        if (params_.ipAssetType == IPAsset.IPAssetType.UNDEFINED) revert Errors.IPAsset_InvalidType(IPAsset.IPAssetType.UNDEFINED);
        // TODO: Add module and other relevant configuration for registration.
        uint256 ipAssetId = REGISTRY.register(msg.sender, address(this));
        uint256 ipAssetOrgId = _mintBlock(params_.to, params_.ipAssetType);
        _writeIPAsset(ipAssetId, ipAssetOrgId, params_.name, params_.description, params_.mediaUrl);
        IPAssetOrgStorage storage $ = _getIPAssetOrgStorage();

        // Non commercial
        // TODO(ramarti): Switch to configuration by IP Asset Registry id.
        Licensing.IPAssetOrgConfig memory config = LICENSING_MODULE
            .getIpAssetOrgConfig(address(this));
        if (config.revoker == address(0)) revert Errors.IPAssetOrg_LicensingNotConfigured();
        _setNonCommercialRights(
            ipAssetOrgId,
            params_.parentIpAssetOrgId,
            params_.to,
            config.revoker,
            config.nonCommercialConfig,
            config.nonCommercialTerms
        );
        // If non derivative IpAsset, then franchise config may dictate commercial rights
        // Derivative works do not have commercial rights unless a deal with the relevant licensor is made
        if (config.rootIpAssetHasCommercialRights && params_.parentIpAssetOrgId == 0) {
            // Commercial
            _setCommercialRights(
                ipAssetOrgId,
                _ROOT_IP_ASSET,
                params_.to,
                config.revoker,
                config.commercialLicenseUri,
                config.commercialConfig,
                config.commercialTerms
            );
        }

        // TODO(@leeren): Add collect NFT impl and other collect data overrides.
        COLLECT_MODULE.initCollect(
            Collect.InitCollectParams({
                ipAssetId: ipAssetId,
                collectNftImpl: address(0), // Default collect module NFT impl
                data: params_.collectData
            })
        );
        return (ipAssetId, ipAssetOrgId);
    }

    /// @notice Retrieves the token URI for an IP Asset within the IP Asset Org.
    /// @param tokenId_ The id of the IP Asset within the IP Asset Org.
    function tokenURI(
        uint256 tokenId_
    ) public view override returns (string memory) {
        // TODO: should this reference the license too?
        return readIPAsset(tokenId_).mediaUrl;
    }

    /// @notice Checks if the contract supports interface `interfaceId_`.
    /// @param interfaceId_ The id of the interface being checked.
    function supportsInterface(
        bytes4 interfaceId_
    ) public
    view
    virtual
    override(ERC721Upgradeable, IERC165Upgradeable)
    returns (bool)
    {
        return
            interfaceId_ == type(IIPAssetOrg).interfaceId ||
            super.supportsInterface(interfaceId_);
    }

    /// Sets the non commercial rights for an IPAsset, with terms from the IPAssetOrg config in LicensingModule.
    /// If no parent asset id is provided, the root IPAsset id is used if it exists in the IPAssetOrg config.
    /// @param ipAssetOrgId_ the IPAsset id
    /// @param parentIpAssetOrgId_ in case this is a derivative IPAsset, set the parent IPAsset id, 0 otherwise
    /// @param holder_ of the IPAsset and licenses
    /// @param revoker_ of the license. Can't be zero or changed later
    /// @param config_ IPAssetOrg config
    /// @param terms_ for the license to be active
    /// TODO(ramarti): Refactor to support IP Asset configuration via the registry - deprecate use of ipAssetOrgId.
    function _setNonCommercialRights(
        uint256 ipAssetOrgId_,
        uint256 parentIpAssetOrgId_,
        address holder_,
        address revoker_,
        Licensing.IpAssetConfig memory config_,
        Licensing.TermsProcessorConfig memory terms_
    ) internal {
        uint256 parentLicenseId = parentIpAssetOrgId_ == 0
            ? config_.ipAssetOrgRootLicenseId
            : getLicenseIdByTokenId(parentIpAssetOrgId_, false);
        _createLicense(
            ipAssetOrgId_,
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

    /// Sets the commercial rights for an IPAsset, with terms from the IPAssetOrg config in LicensingModule.
    /// If no parent asset id is provided, the root IPAsset id is used if it exists in the IPAssetOrg config.
    /// @param ipAssetOrgId_ the IP Asset org id
    /// @param parentIpAssetOrgId_ in case this is a derivative IPAsset, set the parent IPAsset id, 0 otherwise
    /// @param holder_ of the IPAsset and licenses
    /// @param revoker_ of the license. Can't be zero or changed later
    /// @param config_ IPAssetOrg config
    /// @param terms_ for the license to be active
    /// TODO(ramarti): Refactor to support ip asset registry ids instead of ip asset org ids.
    function _setCommercialRights(
        uint256 ipAssetOrgId_,
        uint256 parentIpAssetOrgId_,
        address holder_,
        address revoker_,
        string memory licenseUri_,
        Licensing.IpAssetConfig memory config_,
        Licensing.TermsProcessorConfig memory terms_
    ) internal {
        uint256 parentLicenseId = parentIpAssetOrgId_ == _ROOT_IP_ASSET
            ? config_.ipAssetOrgRootLicenseId
            : getLicenseIdByTokenId(parentIpAssetOrgId_, true);
        _createLicense(
            ipAssetOrgId_,
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

    /// @notice Mints a new IP asset localized for the IP Asset Org.
    /// @param to_ Address of the owner of the IP Asset.
    /// @param ipAssetType_ Type of the IP Asset.
    /// TODO: Deprecate use of IP Asset types in the IP Asset Org contract.
    function _mintBlock(
        address to_,
        IPAsset.IPAssetType ipAssetType_
    ) private returns (uint256) {
        uint256 nextId = currentIdFor(ipAssetType_) + 1;
        if (nextId > IPAsset._lastId(ipAssetType_)) revert Errors.IPAssetOrg_IdOverBounds();
        IPAssetOrgStorage storage $ = _getIPAssetOrgStorage();
        $.idsByType[ipAssetType_] = nextId;
        _safeMint(to_, nextId);
        return nextId;
    }

    /// @notice Gets the next id that a newly minted IP Asset corresponds to.
    /// @param ipAssetType_ The type of the IP Asset being queried.
    function currentIdFor(IPAsset.IPAssetType ipAssetType_) public view returns (uint256) {
        IPAssetOrgStorage storage $ = _getIPAssetOrgStorage();
        uint256 currentId = $.idsByType[ipAssetType_];
        if (currentId == 0) {
            return IPAsset._zeroId(ipAssetType_);
        } else {
            return currentId;
        }
    }

    /// @dev Gets the storage associated with the IPAssetOrg contract.
    function _getIPAssetOrgStorage()
        private
        pure
        returns (IPAssetOrgStorage storage $)
    {
        assembly {
            $.slot := _STORAGE_LOCATION
        }
    }
}
