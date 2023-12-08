// SPDX-License-Identifier: UNLICENSED
// See https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.19;

// This file contains module structures and constants used throughout Story Protocol.

// A module key is identified by its keccak-256 encoded string identifier.
type ModuleKey is bytes32;

using { moduleKeyEquals as == } for ModuleKey global;
using { moduleKeyNotEquals as != } for ModuleKey global;

// A gateway's module dependencies are composed of a list of module keys
// and a list of function selectors dependend on for each of these modules.
struct ModuleDependencies {
    ModuleKey[] keys;
    bytes4[][] fns;
}

// Helper function for comparing equality between two keys.
function moduleKeyEquals(ModuleKey k1, ModuleKey k2) pure returns (bool) {
    return ModuleKey.unwrap(k1) == ModuleKey.unwrap(k2);
}

// Helper function for comparing inequality between two keys.
function moduleKeyNotEquals(ModuleKey k1, ModuleKey k2) pure returns (bool) {
    return ModuleKey.unwrap(k1) != ModuleKey.unwrap(k2);
}

// Transforms a string to its designated module key.
function toModuleKey(string calldata moduleKey_) pure returns (ModuleKey) {
    return ModuleKey.wrap(keccak256(abi.encodePacked(moduleKey_)));
}

// String values for core protocol modules.
string constant RELATIONSHIP_MODULE = "RELATIONSHIP_MODULE";
string constant LICENSING_MODULE = "LICENSING_MODULE";
string constant REGISTRATION_MODULE = "REGISTRATION_MODULE";

// Module key values for core protocol modules.
ModuleKey constant RELATIONSHIP_MODULE_KEY = ModuleKey.wrap(keccak256(abi.encodePacked(RELATIONSHIP_MODULE)));
ModuleKey constant LICENSING_MODULE_KEY = ModuleKey.wrap(keccak256(abi.encodePacked(LICENSING_MODULE)));
ModuleKey constant REGISTRATION_MODULE_KEY = ModuleKey.wrap(keccak256(abi.encodePacked(REGISTRATION_MODULE)));
