// SPDX-License-Identifier: UNLICENSED
// See Story Protocol Alpha Agreement: https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.18;

import { HookRegistry } from "contracts/modules/base/HookRegistry.sol";
import { IIPOrg } from "contracts/interfaces/ip-org/IIPOrg.sol";
import { ModuleRegistry } from "contracts/modules/ModuleRegistry.sol";

/// @title Mock Hook Registry
/// @notice This mock contract is used for testing the base hook registry.
contract MockHookRegistry is HookRegistry {
    constructor(ModuleRegistry moduleRegistry_) HookRegistry(moduleRegistry_) {}

    function hookRegistryKey(
        address ipOrg_,
        string calldata someHookRegisteringRelatedInfo_
    ) public pure returns (bytes32) {
        return _generateRegistryKey(ipOrg_, someHookRegisteringRelatedInfo_);
    }

    function _generateRegistryKey(
        address ipOrg_,
        string memory someHookRegisteringRelatedInfo_
    ) private pure returns (bytes32) {
        return keccak256(abi.encode(ipOrg_, someHookRegisteringRelatedInfo_));
    }
}
