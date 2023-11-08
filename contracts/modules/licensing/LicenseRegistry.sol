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

    
}
