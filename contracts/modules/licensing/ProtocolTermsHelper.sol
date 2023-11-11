// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { Licensing } from "contracts/lib/modules/Licensing.sol";
import { OffChain } from "contracts/lib/OffChain.sol";
import { TermsHook } from "contracts/hooks/licensing/TermsHook.sol";

abstract contract ProtocolTermsHelper {

    function getSelector(string memory func_) public pure returns (bytes4) {
        return bytes4(keccak256(bytes(func_)));
    }

    function getExcludedCategoriesTerm(
        Licensing.CommercialStatus comStatus_,
        TermsHook hook
    ) public pure returns (Licensing.LicensingTerm memory) {
        return Licensing.LicensingTerm({
            comStatus: comStatus_,
            text: OffChain.Content({
                url: "https://excluded.com"
            }),
            hook: hook
        });
    }
}