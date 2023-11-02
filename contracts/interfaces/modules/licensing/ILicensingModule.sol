// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;
import { ZeroAddress, Unauthorized } from "contracts/errors/General.sol";
import { IPOrgFactory } from "contracts/ip-org/IPOrgFactory.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { AccessControlledUpgradeable } from "contracts/access-control/AccessControlledUpgradeable.sol";
import { ITermsProcessor } from "./terms/ITermsProcessor.sol";
import { Licensing } from "contracts/lib/modules/Licensing.sol";
import { IERC5218 } from "./IERC5218.sol";

interface ILicensingModule {
    
    event NonCommercialLicenseUriSet(string uri);

    event IPOrgConfigSet(address ipAssetOrg, Licensing.IPOrgConfig config);

    function configureIpOrgLicensing(address ipAssetOrg_, Licensing.IPOrgConfig memory config_) external;

    function getIpOrgConfig(address ipAssetOrg_) external view returns (Licensing.IPOrgConfig memory);

    function getNonCommercialLicenseURI() external view returns (string memory);

}
