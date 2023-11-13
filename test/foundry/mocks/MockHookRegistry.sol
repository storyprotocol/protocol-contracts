// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import { HookRegistry } from "contracts/modules/base/HookRegistry.sol";
import { IIPOrg } from "contracts/interfaces/ip-org/IIPOrg.sol";

/// @title Mock Hook Registry
/// @notice This mock contract is used for testing the base hook registry.
contract MockHookRegistry is HookRegistry {
    address public immutable ADMIN;


    constructor() {
        ADMIN = msg.sender;
    }

    function _hookRegistryAdmin()
        internal
        view
        virtual
        override
        returns (address)
    {
        return ADMIN;
    }

    function hookRegistryKey(
        address ipOrg_,
        string calldata someHookRegisteringRelatedInfo_
    ) public pure returns(bytes32) {
        return _generateRegistryKey(ipOrg_, someHookRegisteringRelatedInfo_);
    }

    function _generateRegistryKey(
        address ipOrg_,
        string memory someHookRegisteringRelatedInfo_
    ) private pure returns(bytes32) {
        return keccak256(abi.encode(ipOrg_, someHookRegisteringRelatedInfo_));
    }
}
