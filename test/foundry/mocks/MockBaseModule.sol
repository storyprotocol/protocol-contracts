// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import { BaseModule } from "contracts/modules/base/BaseModule.sol";

/// @title Mock BaseModule
/// @notice This mock contract is used for testing the base module flow
contract MockBaseModule is BaseModule {
    address private _admin;

    struct BaseModuleCall {
        address caller;
        bytes params;
    }

    BaseModuleCall[] private _callStack;

    constructor(
        address admin_,
        ModuleConstruction memory params_
    ) BaseModule(params_) {
        _admin = admin_;
    }

    function callStackAt(uint256 index_)
        external
        view
        returns (BaseModuleCall memory)
    {
        return _callStack[index_];
    }

    function _hookRegistryAdmin()
        internal
        view
        virtual
        override
        returns (address)
    {
        return _admin;
    }

    function _configure(
        address caller_,
        bytes calldata params_
    ) internal virtual override {
        _callStack.push(BaseModuleCall(caller_, params_));
    }

    function _verifyExecution(
        address caller_,
        bytes calldata params_
    ) internal virtual override {
        _callStack.push(BaseModuleCall(caller_, params_));
    }

    function _performAction(
        address caller_,
        bytes calldata params_
    ) internal virtual override {
        _callStack.push(BaseModuleCall(caller_, params_));
    }


}
