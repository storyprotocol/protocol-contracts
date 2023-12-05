// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { Licensing } from "contracts/lib/modules/Licensing.sol";
import { ShortString, ShortStrings } from "@openzeppelin/contracts/utils/ShortStrings.sol";
import { Errors } from "contracts/lib/Errors.sol";

/// List of Protocol Term Ids (meaning the Licensing Module will have specific instructions
/// for these terms without the need of a decoder)
/// @dev must be < 32 bytes long, or they will blow up at some point
/// see https://docs.openzeppelin.com/contracts/4.x/api/utils#ShortStrings
library PIPLicensingTerms {
    using ShortStrings for *;

    string constant CHANNELS_OF_DISTRIBUTION = "Channels-Of-Distribution";
    string constant ATTRIBUTION = "Attribution";
    string constant DERIVATIVES_WITH_ATTRIBUTION = "Derivatives-With-Attribution";
    string constant DERIVATIVES_WITH_APPROVAL = "Derivatives-With-Approval";
    string constant DERIVATIVES_WITH_RECIPROCAL_LICENSE = "Derivatives-With-Reciprocal-License";

    // On beta version
    // string constant CONTENT_STANDARDS = "Content-Standards";
    // string constant DERIVATIVES = "Derivatives";
    // string constant TERRITORY = "TERRITORY";
    // string constant REVOCABLE = "REVOCABLE";
    // string constant COMMERCIAL_USE = "COMMERCIAL_USE";
    // string constant GROSS_REVENUES = "GROSS_REVENUES";
    // string constant LICENSE_FEE = "LICENSE_FEE";
    // string constant SUBLICENSABLE = "SUBLICENSABLE";
    // string constant TRANSFERABLE = "TRANSFERABLE";
    // string constant CURRENCY = "CURRENCY";
    // string constant PAYMENT_ADDRESS = "PAYMENT_ADDRESS";
    // string constant GOVERNING_LAW = "GOVERNING_LAW";
    // string constant EXPIRATION = "EXPIRATION";
    // string constant ALTERNATIVE_DISPUTE_RESOLUTION =
    //    "ALTERNATIVE_DISPUTE_RESOLUTION";

    function _getParamDefs()
        internal
        pure
        returns (Licensing.ParamDefinition[] memory paramDefs)
    {
        paramDefs = new Licensing.ParamDefinition[](5);
        paramDefs[0] = Licensing.ParamDefinition(
            CHANNELS_OF_DISTRIBUTION.toShortString(),
            Licensing.ParameterType.MultipleChoice
        );
        paramDefs[1] = Licensing.ParamDefinition(
            ATTRIBUTION.toShortString(),
            Licensing.ParameterType.Bool
        );
        paramDefs[2] = Licensing.ParamDefinition(
            DERIVATIVES_WITH_ATTRIBUTION.toShortString(),
            Licensing.ParameterType.Bool
        );
        paramDefs[3] = Licensing.ParamDefinition(
            DERIVATIVES_WITH_APPROVAL.toShortString(),
            Licensing.ParameterType.Bool
        );
        paramDefs[4] = Licensing.ParamDefinition(
            DERIVATIVES_WITH_RECIPROCAL_LICENSE.toShortString(),
            Licensing.ParameterType.Bool
        );
    }

}
