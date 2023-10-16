// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;
import { ZeroAddress, Unauthorized } from "contracts/errors/General.sol";
import { IPAssetController } from "contracts/IPAssetController.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { AccessControlledUpgradeable } from "contracts/access-control/AccessControlledUpgradeable.sol";
import { ITermsProcessor } from "./terms/ITermsProcessor.sol";
import { Licensing } from "contracts/lib/modules/Licensing.sol";
import { IERC5218 } from "./IERC5218.sol";

interface ILicensingModule {
    
    event NonCommercialLicenseUriSet(string uri);

    event IPAssetGroupConfigSet(uint256 franchiseId, Licensing.IPAssetGroupConfig config);

    function configureIPAssetGroupLicensing(uint256 franchiseId_, Licensing.IPAssetGroupConfig memory config_) external;
    function getIPAssetGroupConfig(uint256 franchiseId_) external view returns (Licensing.IPAssetGroupConfig memory);
    function getNonCommercialLicenseURI() external view returns (string memory);

}
