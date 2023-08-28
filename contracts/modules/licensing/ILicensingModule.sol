// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;
import { ZeroAddress, Unauthorized } from "contracts/errors/General.sol";
import { FranchiseRegistry } from "contracts/FranchiseRegistry.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { AccessControlledUpgradeable } from "contracts/access-control/AccessControlledUpgradeable.sol";
import { UPGRADER_ROLE, LICENSING_MANAGER_ROLE } from "contracts/access-control/ProtocolRoles.sol";
import { ITermsProcessor } from "./terms/ITermsProcessor.sol";
import { IERC5218 } from "./IERC5218.sol";

interface ILicensingModule {
    
    struct IpAssetConfig {
        bool canSublicense;
        uint256 franchiseRootLicenseId;
        // TODO: allowed license terms? processors?
        // TODO: limit medium of sublicenses? something like LibIPAssetMask?
        // TODO: limit who you can sublicense to?
    }

    struct FranchiseConfig {
        IpAssetConfig nonCommercialConfig;
        IERC5218.TermsProcessorConfig nonCommercialTerms;
        IpAssetConfig commercialConfig;
        IERC5218.TermsProcessorConfig commercialTerms;
        bool rootIpAssetHasCommercialRights;
        address revoker;
        string commercialLicenseUri;
        
    }

    event FranchiseConfigSet(uint256 franchiseId, FranchiseConfig config);


    function configureFranchiseLicensing(uint256 franchiseId, FranchiseConfig memory config) external;
    function getFranchiseConfig(uint256 franchiseId) external view returns (FranchiseConfig memory);
    function getNonCommercialLicenseURI() external view returns (string memory);

}