// SPDX-License-Identifier: BUSL-1.1
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
