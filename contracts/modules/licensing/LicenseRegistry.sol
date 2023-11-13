// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { Licensing } from "contracts/lib/modules/Licensing.sol";
import { IIPAssetRegistry } from "contracts/interfaces/IIPAssetRegistry.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract LicenseRegistry is ERC721 {
    event LicenseAdded(
        uint256 indexed id
    );
    event LicenseeTypeChanged(
        uint256 indexed id,
        Licensing.LicenseeType oldType,
        Licensing.LicenseeType newType
    );

    mapping(uint256 => Licensing.License) private _licenses;
    uint256 private _licenseCount;

    // TODO: This should IRelationshipRegistry, just to check IPA_LICENSE
    //RelationshipModule immutable REL_MODULE;

    constructor(
        // address relModule
    ) ERC721("Story Protocol License NFT", "LNFT") {
        // if (relModule == address(0)) {
        //    revert Errors.LicenseRegistry_ZeroRelRegistryAddress();
        // }
        // REL_MODULE = RelationshipModule(relModule);
    }

    function addLicense(
        Licensing.License memory license_,
        address licensee_
    ) external returns (uint256) {
        // TOOD: Add authorization
        _licenseCount++;
        _licenses[_licenseCount] = license_;
        emit LicenseAdded(_licenseCount);
        if (license_.licenseeType == Licensing.LicenseeType.LNFTHolder) {
            _safeMint(licensee_, _licenseCount);
        }
        return _licenseCount;
    }

    function getLicense(
        uint256 id_
    ) external view returns (Licensing.License memory) {
        return _licenses[id_];
    }

    function getLicensee(
        uint256 id_
    ) external view returns (address) {
        if (_licenses[id_].licenseeType == Licensing.LicenseeType.LNFTHolder) {
            return ownerOf(id_);
        } else {
            // TODO get IPA owner
            return address(0);
        }
    }

    function boundLnftToIpa(
        uint256 id_
    ) external {
        // TODO add Authorization and 
        Licensing.License memory license_ = _licenses[id_];
        if (license_.licenseeType != Licensing.LicenseeType.LNFTHolder) {
            revert Errors.LicenseRegistry_LicenseNotBoundToLnft();
        }
        _licenses[id_].licenseeType = Licensing.LicenseeType.BoundToIpa;
        _burn(id_);
        emit LicenseeTypeChanged(
            id_,
            Licensing.LicenseeType.LNFTHolder,
            Licensing.LicenseeType.BoundToIpa
        );
    }
}
