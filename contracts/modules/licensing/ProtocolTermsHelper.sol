// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { Licensing } from "contracts/lib/modules/Licensing.sol";
import { OffChain } from "contracts/lib/OffChain.sol";

abstract contract ProtocolTermsHelper {

    function getSelector(string memory func_) public pure returns (bytes4) {
        return bytes4(keccak256(bytes(func_)));
    }

    function getExcludedCategoriesTerm(
        Licensing.CommercialStatus comStatus_,
        address decoder_,
        string[] calldata excluded_
    ) public pure returns (Licensing.LicensingTerm memory) {
        return Licensing.LicensingTerm({
            comStatus: comStatus_,
            text: OffChain.Content({
                url: "https://excluded.com"
            }),
            decoder: decoder_,
            selector: getSelector("decodeStringArray(string[])"),
            data: abi.encode(excluded_)
        });
    }
}