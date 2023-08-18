// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;
import { ZeroAddress, Unauthorized } from "contracts/errors/General.sol";
import { FranchiseRegistry } from "contracts/FranchiseRegistry.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { AccessControlledUpgradeable } from "contracts/access-control/AccessControlledUpgradeable.sol";
import { UPGRADER_ROLE, LICENSING_MANAGER_ROLE } from "contracts/access-control/ProtocolRoles.sol";

contract LicensingModule is AccessControlledUpgradeable {
    
    struct IpAssetConfig {
        bool canSublicense;
        uint256 franchiseRootLicenseId;
        // TODO: allowed license terms? processors?
        // TODO: limit medium of sublicenses? something like LibIPAssetMask?
    }

    struct FranchiseConfig {
        IpAssetConfig commercialConfig;
        IpAssetConfig nonCommercialConfig;
        bool rootIpAssetHasCommercialRights;
    }

    struct LicensingModuleStorage {
        /// franchiseId => FranchiseConfig
        mapping(uint256 => FranchiseConfig) franchiseConfigs;
        string nonCommercialLicenseURI;
    }

    event NonCommercialLicenseUriSet(string uri);
    event FranchiseConfigSet(uint256 franchiseId, FranchiseConfig config);

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

    function configureLicense(uint256 franchiseId, FranchiseConfig memory config) external {
        if (msg.sender != FRANCHISE_REGISTRY.ownerOf(franchiseId)) {
            revert Unauthorized();
        }
        LicensingModuleStorage storage $ = _getLicensingModuleStorage();
        $.franchiseConfigs[franchiseId] = config;
        emit FranchiseConfigSet(franchiseId, config);
    }

    function getFranchiseConfig(uint256 franchiseId) public view returns (FranchiseConfig memory) {
        return _getLicensingModuleStorage().franchiseConfigs[franchiseId];
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyRole(UPGRADER_ROLE) {}
}