// SPDX-License-Identifier: UNLICENSED
// See https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.18;

import { MockBaseModule } from "./MockBaseModule.sol";
import { Gateway } from "contracts/modules/Gateway.sol";
import { ModuleKey, ModuleDependencies } from "contracts/lib/modules/Module.sol";
import { ModuleRegistry } from "contracts/modules/ModuleRegistry.sol";

/// @title Mock Gateway
/// @notice This mock contract is used for testing the gateway.
contract MockGateway is Gateway {

    ModuleKey constant TEST_MODULE_KEY = ModuleKey.wrap(keccak256(abi.encodePacked("test")));

    bool isValid;
    MockBaseModule module;

    constructor(bool isValid_, ModuleRegistry moduleRegistry_) Gateway(moduleRegistry_) {
        isValid = isValid_;
    }

    function updateDependencies() 
        external 
        override 
        onlyModuleRegistry 
        returns (ModuleDependencies memory dependencies) 
    {
        // Synchronize relevant modules with the registry.
        module = MockBaseModule(MODULE_REGISTRY.protocolModule(TEST_MODULE_KEY));
        return getDependencies();
    }

    function getDependencies() public view override returns (ModuleDependencies memory dependencies) {
        ModuleKey[] memory keys;
        bytes4[][] memory fns;
        if (!isValid) {
            keys = new ModuleKey[](1);
            fns = new bytes4[][](2);

            keys[0] = TEST_MODULE_KEY;
            bytes4[] memory moduleFns = new bytes4[](2);
            fns[0] = moduleFns;

        } else {
            keys = new ModuleKey[](1);
            fns = new bytes4[][](1);
            keys[0] = TEST_MODULE_KEY;
            bytes4[] memory moduleFns = new bytes4[](1);
            moduleFns[0] = MockBaseModule.test.selector;
            fns[0] = moduleFns;
        }
        return ModuleDependencies(keys, fns);
    }

    function setIsValid(bool isValid_) public {
        isValid = isValid_;
    }

    function callModule() external {
        return module.test();
    }
}
