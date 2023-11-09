// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;
import { Errors } from "contracts/lib/Errors.sol";
import { IPOrgController } from "contracts/ip-org/IPOrgController.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { AccessControlledUpgradeable } from "contracts/access-control/AccessControlledUpgradeable.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { ITermsProcessor } from "contracts/interfaces/modules/licensing/terms/ITermsProcessor.sol";
import { IIPOrg } from "contracts/interfaces/ip-org/IIPOrg.sol";
import { IERC5218 } from "contracts/interfaces/modules/licensing/IERC5218.sol";
import { ILicensingModule } from "contracts/interfaces/modules/licensing/ILicensingModule.sol";
import { Licensing } from "contracts/lib/modules/Licensing.sol";


/// @title LicensingModule
/// @author Raul Martinez
/// @notice Contract for configuring and managing licensing for a IPOrg.
/// A licensing framework may be definbed through a IPOrgConfig, which is set by the IPOrg owner.
/// The non commercial license URI is set by a protocol admin key, since it will be common for all Story Protocol
contract LicensingModule is ILicensingModule, AccessControlledUpgradeable {

    struct LicensingModuleStorage {
        /// ipAssetOrgId => IPOrgConfig
        mapping(address => Licensing.IPOrgConfig) ipAssetOrgConfigs;
        string nonCommercialLicenseURI;
    }

    // keccak256(bytes.concat(bytes32(uint256(keccak256("story-protocol.licensing-module.storage")) - 1)))
    bytes32 private constant _STORAGE_LOCATION = 0x80b4ea8c21e869c68acfd93c8ef2c0d867835b92e2fded15a1d74d7e7ff3312d;

    IPOrgController public immutable IP_ASSET_ORG_FACTORY;

    constructor(address franchise_) {
        if (franchise_ == address(0)) {
            revert Errors.ZeroAddress();
        }
        IP_ASSET_ORG_FACTORY = IPOrgController(franchise_);
        _disableInitializers();
    }

    function initialize(address accessControl_, string calldata nonCommercialLicenseUri_) public initializer {
        __AccessControlledUpgradeable_init(accessControl_);
        _getLicensingModuleStorage().nonCommercialLicenseURI = nonCommercialLicenseUri_;
    }

    function _getLicensingModuleStorage() internal pure returns (LicensingModuleStorage storage $) {
        bytes32 position = _STORAGE_LOCATION;
        assembly {
            $.slot := position
        }
    }

    function getNonCommercialLicenseURI() public view returns (string memory) {
        return _getLicensingModuleStorage().nonCommercialLicenseURI;
    }

    
    /// Set the URI for non-commercial licenses across Story Protocol. Setting this does NOT affect existing licenses, only new ones.
    /// @param nonCommercialLicenseURI_ The URI to set for non-commercial licenses
    function setNonCommercialLicenseURI(string calldata nonCommercialLicenseURI_) external onlyRole(AccessControl.LICENSING_MANAGER_ROLE) {
        _getLicensingModuleStorage().nonCommercialLicenseURI = nonCommercialLicenseURI_;
        emit NonCommercialLicenseUriSet(nonCommercialLicenseURI_);
    }

    
    /// Set the IPOrgConfig for a IPOrg, configuring its licensing framework.
    /// @dev if setting root licenses, they should be active. A revoker address must be set, and it will be
    /// common for all licenses in the IPOrg.
    /// @param ipAssetOrg_ The address of the IPOrg to set the config for
    /// @param config_ The IPOrgConfig to set
    function configureIpOrgLicensing(address ipAssetOrg_, Licensing.IPOrgConfig memory config_) external {
        if (msg.sender != IIPOrg(ipAssetOrg_).owner()) {
            revert Errors.Unauthorized();
        }
        _verifyRootLicense(ipAssetOrg_, config_.nonCommercialConfig.ipAssetOrgRootLicenseId);
        _verifyRootLicense(ipAssetOrg_, config_.commercialConfig.ipAssetOrgRootLicenseId);
        if (config_.revoker == address(0)) {
            revert Errors.LicensingModule_ZeroRevokerAddress();
        }
        LicensingModuleStorage storage $ = _getLicensingModuleStorage();
        $.ipAssetOrgConfigs[ipAssetOrg_] = config_;
        emit IPOrgConfigSet(ipAssetOrg_, config_);
    }

    function _verifyRootLicense(address ipAssetOrg_, uint256 rootLicenseId_) internal view {
        if (rootLicenseId_ != 0) {
            IERC5218 rightsManager = IERC5218(ipAssetOrg_);
            if (address(rightsManager) == address(0)) {
                // IP_ASSET_ORG_FACTORY.ownerOf(ipAssetOrgId) should take care of this,
                // but leaving it in case IPAssetRegistration creation fails somewhow.
                revert Errors.LicensingModule_NonExistentIPOrg();
            }
            if (!rightsManager.isLicenseActive(rootLicenseId_)) {
                revert Errors.LicensingModule_RootLicenseNotActive(rootLicenseId_);
            }
        }
    }

    function getIpOrgConfig(address ipAssetOrg_) public view returns (Licensing.IPOrgConfig memory) {
        return _getLicensingModuleStorage().ipAssetOrgConfigs[ipAssetOrg_];
    }

    function _authorizeUpgrade(
        address newImplementation_
    ) internal virtual override onlyRole(AccessControl.UPGRADER_ROLE) {}
}
