// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { Licensing } from "contracts/lib/modules/Licensing.sol";

contract LicenseRegistry {

    mapping(uint256 => Licensing.License) private _licenses;
    uint256 private _licenseCount = 0;

    
    function addLicense(Licensing.License calldata license_) external returns (uint256) {
        // TOOD: Add authorization
        _licenseCount++;
        _licenses[_licenseCount] = license_;
        return _licenseCount;
    }

    function getLicense(uint256 id_) external view returns (Licensing.License memory) {
        return _licenses[id_];
    }

    function getLicenseOwner(uint256 id_) external view returns (address) {
        return address(123);
    }

    function addTerms(uint256 licenseId, bytes[] memory terms) external {
    }

    function makeTradeable(uint256 licenseId_) external {
    }
}
