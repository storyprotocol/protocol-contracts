// SPDX-License-Identifier: UNLICENSED
// See Story Protocol Alpha Agreement: https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.18;

import { BaseModule } from "contracts/modules/base/BaseModule.sol";
import { IIPOrg } from "contracts/interfaces/ip-org/IIPOrg.sol";
import { ModuleKey } from "contracts/lib/modules/Module.sol";

/// @title Mock BaseModule
/// @notice This mock contract is used for testing the base module flow
contract MockBaseModule is BaseModule {
    address private _admin;

    struct ModuleExecutionParams {
        uint256 paramA;
        uint256 paramC;
        string someHookRegisteringRelatedInfo;
    }

    struct BaseModuleCall {
        address ipOrg;
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

    // Stub for testing authorization via the module registry.
    function test() external onlyAuthorized() {}

    function moduleKey() public pure override returns (ModuleKey) {
        return ModuleKey.wrap(keccak256(abi.encodePacked("test")));
    }

    function callStackAt(
        uint256 index_
    ) external view returns (BaseModuleCall memory) {
        return _callStack[index_];
    }

    function _configure(
        IIPOrg ipOrg_,
        address caller_,
        bytes calldata params_
    ) internal virtual override returns (bytes memory) {
        _callStack.push(BaseModuleCall(address(ipOrg_), caller_, params_));
    }

    function _verifyExecution(
        IIPOrg ipOrg_,
        address caller_,
        bytes calldata params_
    ) internal virtual override {
        _callStack.push(BaseModuleCall(address(ipOrg_), caller_, params_));
    }

    function _performAction(
        IIPOrg ipOrg_,
        address caller_,
        bytes memory params_
    ) internal virtual override returns (bytes memory) {
        _callStack.push(BaseModuleCall(address(ipOrg_), caller_, params_));
        return "";
    }

    function registerHooks(
        HookType hType_,
        IIPOrg ipOrg_,
        string memory hookRegistrationInfo_,
        address[] calldata hooks_,
        bytes[] calldata hooksConfig_
    ) external onlyIpOrgOwner(ipOrg_) {
        bytes32 registryKey = _generateRegistryKey(address(ipOrg_), hookRegistrationInfo_);
        registerHooks(hType_, ipOrg_, registryKey, hooks_, hooksConfig_);
    }

    function hookRegistryKey(
        address ipOrg_,
        string calldata hookRegistrationInfo_
    ) external pure returns(bytes32) {
        return _generateRegistryKey(ipOrg_, hookRegistrationInfo_);
    }

    function _hookRegistryKey(
        IIPOrg ipOrg_,
        address,
        bytes calldata params_
    ) internal view virtual override returns(bytes32) {
        ModuleExecutionParams memory moduleParams = abi.decode(params_, (ModuleExecutionParams));
        return _generateRegistryKey(address(ipOrg_), moduleParams.someHookRegisteringRelatedInfo);
    }

    function _generateRegistryKey(
        address ipOrg_,
        string memory hookRegistrationInfo_
    ) private pure returns(bytes32) {
        return keccak256(abi.encode(ipOrg_, hookRegistrationInfo_));
    }


}
