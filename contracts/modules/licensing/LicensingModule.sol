// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;
import { ZeroAddress, Unauthorized } from "contracts/errors/General.sol";
import { FranchiseRegistry } from "contracts/FranchiseRegistry.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { AccessControlledUpgradeable } from "contracts/access-control/AccessControlledUpgradeable.sol";
import { UPGRADER_ROLE, LICENSING_MANAGER_ROLE } from "contracts/access-control/ProtocolRoles.sol";
import { ITermsProcessor } from "./terms/ITermsProcessor.sol";
import { IERC5218 } from "./IERC5218.sol";
import { ILicensingModule } from "./ILicensingModule.sol";
import "forge-std/console.sol";

contract LicensingModule is ILicensingModule, AccessControlledUpgradeable {

    struct LicensingModuleStorage {
        /// franchiseId => FranchiseConfig
        mapping(uint256 => FranchiseConfig) franchiseConfigs;
        string nonCommercialLicenseURI;
    }

    event NonCommercialLicenseUriSet(string uri);

    error NonExistentFranchise();
    error RootLicenseNotActive(uint256 rootLicenseId);
    error ZeroRevokerAddress();

    // keccak256(bytes.concat(bytes32(uint256(keccak256("story-protocol.licensing-module.storage")) - 1)))
    bytes32 private constant _STORAGE_LOCATION = 0x80b4ea8c21e869c68acfd93c8ef2c0d867835b92e2fded15a1d74d7e7ff3312d;

    FranchiseRegistry public immutable FRANCHISE_REGISTRY;

    constructor(address franchiseRegistry) {
        if (franchiseRegistry == address(0)) {
            revert ZeroAddress();
        }
        FRANCHISE_REGISTRY = FranchiseRegistry(franchiseRegistry);
        _disableInitializers();
    }

    function initialize(address accessControl, string calldata nonCommercialLicenseUri) public initializer {
        __AccessControlledUpgradeable_init(accessControl);
        _getLicensingModuleStorage().nonCommercialLicenseURI = nonCommercialLicenseUri;
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

    function setNonCommercialLicenseURI(string calldata _nonCommercialLicenseURI) external onlyRole(LICENSING_MANAGER_ROLE) {
        _getLicensingModuleStorage().nonCommercialLicenseURI = _nonCommercialLicenseURI;
        emit NonCommercialLicenseUriSet(_nonCommercialLicenseURI);
    }

    function configureFranchiseLicensing(uint256 franchiseId, FranchiseConfig memory config) external {
        if (msg.sender != FRANCHISE_REGISTRY.ownerOf(franchiseId)) {
            revert Unauthorized();
        }
        _verifyRootLicense(franchiseId, config.nonCommercialConfig.franchiseRootLicenseId);
        _verifyRootLicense(franchiseId, config.commercialConfig.franchiseRootLicenseId);
        if (config.revoker == address(0)) {
            revert ZeroRevokerAddress();
        }
        LicensingModuleStorage storage $ = _getLicensingModuleStorage();
        $.franchiseConfigs[franchiseId] = config;
        emit FranchiseConfigSet(franchiseId, config);
    }

    function _verifyRootLicense(uint256 franchiseId, uint256 rootLicenseId) internal view {
        console.log("rootLicenseId", rootLicenseId);
        if (rootLicenseId != 0) {
            IERC5218 rightsManager = IERC5218(FRANCHISE_REGISTRY.ipAssetRegistryForId(franchiseId));
            if (address(rightsManager) == address(0)) {
                // FRANCHISE_REGISTRY.ownerOf(franchiseId) should take care of this,
                // but leaving it in case IPAssetRegistration creation fails somewhow.
                revert NonExistentFranchise();
            }
            console.log("rightsManager.isLicenseActive(rootLicenseId)", rightsManager.isLicenseActive(rootLicenseId));
            if (!rightsManager.isLicenseActive(rootLicenseId)) {
                revert RootLicenseNotActive(rootLicenseId);
            }
        }
    }

    function getFranchiseConfig(uint256 franchiseId) public view returns (FranchiseConfig memory) {
        return _getLicensingModuleStorage().franchiseConfigs[franchiseId];
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyRole(UPGRADER_ROLE) {}
}