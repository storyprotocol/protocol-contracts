// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { Licensing } from "contracts/lib/modules/Licensing.sol";
import { TermsHook } from "contracts/hooks/licensing/TermsHook.sol";
import { IHook } from "contracts/interfaces/hooks/base/IHook.sol";

library ProtocolTermsHelper {

    function _getExcludedCategoriesTerm(
        Licensing.CommercialStatus comStatus_,
        TermsHook hook
    ) internal pure returns (Licensing.LicensingTerm memory) {
        return Licensing.LicensingTerm({
            comStatus: comStatus_,
            url: "https://excluded.com",
            hash: "qwertyu",
            algorithm: "sha256",
            hook: hook
        });
    }

    function _getNftShareAlikeTerm(
        Licensing.CommercialStatus comStatus_
    ) internal pure returns (Licensing.LicensingTerm memory) {
        return Licensing.LicensingTerm({
            comStatus: comStatus_,
            url: "https://sharealike.com",
            hash: "qwertyu",
            algorithm: "sha256",
            hook: IHook(address(0))
        });
    }

}