// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { HookResult } from "contracts/interfaces/hooks/base/IHook.sol";
import { SyncBaseHook } from "contracts/hooks/base/SyncBaseHook.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { TermsHooks } from "contracts/lib/hooks/licensing/TermsHooks.sol";
import { ShortStrings } from "@openzeppelin/contracts/utils/ShortStrings.sol";
import { ShortStringOps } from "contracts/utils/ShortStringOps.sol";
import { TermIds, Licensing } from "contracts/lib/modules/Licensing.sol";

contract TermsHook is SyncBaseHook {
    using ShortStrings for *;


    constructor(address accessControl_) SyncBaseHook(accessControl_) {}

    function _validateConfig(bytes memory hookConfig_) internal pure override {
        Licensing.TermsConfig memory config = abi.decode(hookConfig_, (Licensing.TermsConfig));
        // abi.decode still cannot be try/catched, so we cannot return meaningful errors.
        // If config is correct, this will not revert
        // See https://github.com/ethereum/solidity/issues/13869
        if (ShortStringOps._equal(TermIds.SHARE_ALIKE, config.termId)) {
            abi.decode(config.data, (TermsHooks.ShareAlike));
        }
        revert Errors.TermsHook_UnsupportedTermsId();
    }

    function _executeSyncCall(
        bytes memory hookConfig_,
        bytes memory hookParams_
    ) internal virtual override returns (bytes memory) {
        Licensing.TermsConfig memory config = abi.decode(hookConfig_, (Licensing.TermsConfig));
        if (ShortStringOps._equal(TermIds.SHARE_ALIKE, config.termId)) {
            abi.decode(config.data, (TermsHooks.ShareAlike));
        }
        return "";
    }
}
