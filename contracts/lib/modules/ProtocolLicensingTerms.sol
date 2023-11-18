// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

/// List of Licensing Term categories
library TermCategories {
    string constant CATEGORIZATION = "CATEGORIZATION";
    string constant SHARE_ALIKE = "SHARE_ALIKE";
    string constant ACTIVATION = "ACTIVATION";
    string constant LICENSOR = "LICENSOR";
}

/// List of Protocol Term Ids (meaning the Licensing Module will have specific instructions
/// for these terms without the need of a decoder)
/// @dev must be < 32 bytes long, or they will blow up at some point
/// see https://docs.openzeppelin.com/contracts/4.x/api/utils#ShortStrings
library TermIds {
    string constant NFT_SHARE_ALIKE = "NFT_SHARE_ALIKE";
    string constant LICENSOR_APPROVAL = "LICENSOR_APPROVAL";
    string constant FORMAT_CATEGORY = "FORMAT_CATEGORY";
    string constant LICENSOR_IPORG_OR_PARENT = "LICENSOR_IPORG_OR_PARENT";
}

library TermsData {
    enum LicensorConfig {
        Unset,
        IpOrg,
        ParentLicensee
    }
}