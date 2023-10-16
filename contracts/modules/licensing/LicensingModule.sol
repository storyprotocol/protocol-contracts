// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;
import { Errors } from "contracts/lib/Errors.sol";
import { IPAssetController } from "contracts/IPAssetController.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { AccessControlledUpgradeable } from "contracts/access-control/AccessControlledUpgradeable.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { ITermsProcessor } from "contracts/interfaces/modules/licensing/terms/ITermsProcessor.sol";
import { IERC5218 } from "contracts/interfaces/modules/licensing/IERC5218.sol";
import { ILicensingModule } from "contracts/interfaces/modules/licensing/ILicensingModule.sol";
import { Licensing } from "contracts/lib/modules/Licensing.sol";


/// @title LicensingModule
/// @author Raul Martinez
/// @notice Contract for configuring and managing licensing for a IPAssetGroup.
/// A licensing framework may be definbed through a IPAssetGroupConfig, which is set by the IPAssetGroup owner.
/// The non commercial license URI is set by a protocol admin key, since it will be common for all Story Protocol
contract LicensingModule is ILicensingModule, AccessControlledUpgradeable {

    struct LicensingModuleStorage {
        /// franchiseId => IPAssetGroupConfig
        mapping(uint256 => Licensing.IPAssetGroupConfig) franchiseConfigs;
        string nonCommercialLicenseURI;
    }

    // keccak256(bytes.concat(bytes32(uint256(keccak256("story-protocol.licensing-module.storage")) - 1)))
    bytes32 private constant _STORAGE_LOCATION = 0x80b4ea8c21e869c68acfd93c8ef2c0d867835b92e2fded15a1d74d7e7ff3312d;

    IPAssetController public immutable FRANCHISE_REGISTRY;

    constructor(address ipAssetController_) {
        if (ipAssetController_ == address(0)) {
            revert Errors.ZeroAddress();
        }
        FRANCHISE_REGISTRY = IPAssetController(ipAssetController_);
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

    
    /// Set the IPAssetGroupConfig for a IPAssetGroup, configuring its licensing framework.
    /// @dev if setting root licenses, they should be active. A revoker address must be set, and it will be
    /// common for all licenses in the IPAssetGroup.
    /// @param franchiseId_ The ID of the IPAssetGroup to set the config for
    /// @param config_ The IPAssetGroupConfig to set
    function configureIPAssetGroupLicensing(uint256 franchiseId_, Licensing.IPAssetGroupConfig memory config_) external {
        if (msg.sender != FRANCHISE_REGISTRY.ownerOf(franchiseId_)) {
            revert Errors.Unauthorized();
        }
        _verifyRootLicense(franchiseId_, config_.nonCommercialConfig.franchiseRootLicenseId);
        _verifyRootLicense(franchiseId_, config_.commercialConfig.franchiseRootLicenseId);
        if (config_.revoker == address(0)) {
            revert Errors.LicensingModule_ZeroRevokerAddress();
        }
        LicensingModuleStorage storage $ = _getLicensingModuleStorage();
        $.franchiseConfigs[franchiseId_] = config_;
        emit IPAssetGroupConfigSet(franchiseId_, config_);
    }

    function _verifyRootLicense(uint256 franchiseId_, uint256 rootLicenseId_) internal view {
        if (rootLicenseId_ != 0) {
            IERC5218 rightsManager = IERC5218(FRANCHISE_REGISTRY.ipAssetRegistryForId(franchiseId_));
            if (address(rightsManager) == address(0)) {
                // FRANCHISE_REGISTRY.ownerOf(franchiseId) should take care of this,
                // but leaving it in case IPAssetRegistration creation fails somewhow.
                revert Errors.LicensingModule_NonExistentIPAssetGroup();
            }
            if (!rightsManager.isLicenseActive(rootLicenseId_)) {
                revert Errors.LicensingModule_RootLicenseNotActive(rootLicenseId_);
            }
        }
    }

    function getIPAssetGroupConfig(uint256 franchiseId_) public view returns (Licensing.IPAssetGroupConfig memory) {
        return _getLicensingModuleStorage().franchiseConfigs[franchiseId_];
    }

    function _authorizeUpgrade(
        address newImplementation_
    ) internal virtual override onlyRole(AccessControl.UPGRADER_ROLE) {}
}
