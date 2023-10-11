// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;
import { ZeroAddress, Unauthorized } from "contracts/errors/General.sol";
import { FranchiseRegistry } from "contracts/FranchiseRegistry.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { AccessControlledUpgradeable } from "contracts/access-control/AccessControlledUpgradeable.sol";
import { ITermsProcessor } from "./terms/ITermsProcessor.sol";
import { Licensing } from "contracts/lib/modules/Licensing.sol";
import { IERC5218 } from "./IERC5218.sol";

interface ILicensingModule {
    
    event NonCommercialLicenseUriSet(string uri);

    event FranchiseConfigSet(uint256 franchiseId, Licensing.FranchiseConfig config);

    function configureFranchiseLicensing(uint256 franchiseId_, Licensing.FranchiseConfig memory config_) external;
    function getFranchiseConfig(uint256 franchiseId_) external view returns (Licensing.FranchiseConfig memory);
    function getNonCommercialLicenseURI() external view returns (string memory);

}
