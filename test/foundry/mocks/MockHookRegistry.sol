// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import { HookRegistry } from "contracts/modules/base/HookRegistry.sol";

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
}
