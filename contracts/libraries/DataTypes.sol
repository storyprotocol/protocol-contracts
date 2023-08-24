// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

library DataTypes {
    struct FranchiseCreationParams {
        string name;
        string symbol;
        string description;
        string tokenURI;
        address owner;
    }
}
