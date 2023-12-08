// SPDX-License-Identifier: UNLICENSED
// See https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.19;

/// @title IP Org Params Library
/// @notice Library for constants, structs, and helper functions for IP Orgs.
library IPOrgParams {
    struct RegisterIPOrgParams {
        address registry;
        string name;
        string symbol;
        string description;
        string metadataUrl;
    }

    struct InitIPOrgParams {
        address registry;
        address owner;
        string name;
        string symbol;
    }
}
