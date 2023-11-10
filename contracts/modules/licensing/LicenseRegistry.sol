// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { Licensing } from "contracts/lib/modules/Licensing.sol";

contract LicenseRegistry {

    mapping(uint256 => Licensing.License) private _licenses;
    uint256 private _licenseCount = 0;


    function addLicense(Licensing.License calldata license_) external returns (uint256) {
        _licenseCount++;
        _licenses[_licenseCount] = license_;
        return _licenseCount;
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
