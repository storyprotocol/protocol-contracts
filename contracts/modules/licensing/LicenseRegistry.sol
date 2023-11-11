// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { Licensing } from "contracts/lib/modules/Licensing.sol";

contract LicenseRegistry {

    mapping(uint256 => Licensing.License) private _licenses;
    uint256 private _licenseCount = 0;

    mapping(address => uint256) private _ipOrgRootIpLicense;

    function addLicense(Licensing.License calldata license_) external returns (uint256) {
        _licenseCount++;
        _licenses[_licenseCount] = license_;
        return _licenseCount;
    }

    function getLicense(uint256 id_) external view returns (Licensing.License memory) {
        return _licenses[id_];
    }

    function getRootIpLicenseId(address ipOrg_) external view returns (uint256) {
        return _ipOrgRootIpLicense[ipOrg_];
    }

    function getRootIpLicense(address ipOrg_) external view returns (Licensing.License memory) {
        return _licenses[_ipOrgRootIpLicense[ipOrg_]];
    }

    function isLicenseActive(uint256 id_) public view returns (bool) {
        return false;
    }

    function canSublicense(
        uint256 parentLicenseId_,
        bytes memory termsData_
    ) external view returns (bool) {
        return false;
    }

    function createLicenseFrom(
        uint256 parentLicenseId_
    ) external returns (uint256) {
        return _licenseCount++;
    }

    function addTerms(uint256 licenseId, bytes[] memory terms) external {
        _licenses[licenseId].terms = terms;
    }

    function makeTradeable(uint256 licenseId_) external {
    }
}
