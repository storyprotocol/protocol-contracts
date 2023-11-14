// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { Licensing } from "contracts/lib/modules/Licensing.sol";
import { OffChain } from "contracts/lib/OffChain.sol";
import { TermsHook } from "contracts/hooks/licensing/TermsHook.sol";
import { IHook } from "contracts/interfaces/hooks/base/IHook.sol";

library ProtocolTermsHelper {

    function _getExcludedCategoriesTerm(
        Licensing.CommercialStatus comStatus_,
        TermsHook hook
    ) internal pure returns (Licensing.LicensingTerm memory) {
        return Licensing.LicensingTerm({
            comStatus: comStatus_,
            text: OffChain.Content({
                url: "https://excluded.com"
            }),
            hook: hook
        });
    }

    function _getNftShareAlikeTerm(
        Licensing.CommercialStatus comStatus_
    ) internal pure returns (Licensing.LicensingTerm memory) {
        return Licensing.LicensingTerm({
            comStatus: comStatus_,
            text: OffChain.Content({
                url: "https://sharealike.com"
            }),
            hook: IHook(address(0))
        });
    }

}