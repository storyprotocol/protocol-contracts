// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { HookResult } from "contracts/interfaces/hooks/base/IHook.sol";
import { SyncBaseHook } from "contracts/hooks/base/SyncBaseHook.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { ShortStrings, ShortString } from "@openzeppelin/contracts/utils/ShortStrings.sol";
import { ShortStringOps } from "contracts/utils/ShortStringOps.sol";
import { Licensing } from "contracts/lib/modules/Licensing.sol";
import { TermIds, TermData } from "contracts/lib/modules/ProtocolLicensingTerms.sol";

contract TermsHook is SyncBaseHook {
    using ShortStrings for *;

    constructor(address accessControl_) SyncBaseHook(accessControl_) {}

    function _validateConfig(bytes memory hookConfig_) internal pure override {
        (ShortString termId, bytes memory data) = abi.decode(hookConfig_, (ShortString, bytes));
        // abi.decode still cannot be try/catched, so we cannot return meaningful errors.
        // If config is correct, this will not revert
        // See https://github.com/ethereum/solidity/issues/13869
        revert Errors.TermsHook_UnsupportedTermsId();
    }

    function _executeSyncCall(
        bytes memory hookConfig_,
        bytes memory hookParams_
    ) internal virtual override returns (bytes memory) {
        (ShortString termId, bytes memory data) = abi.decode(hookConfig_, (ShortString, bytes));

        return "";
    }
}
