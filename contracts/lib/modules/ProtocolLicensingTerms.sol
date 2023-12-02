// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { Licensing } from "contracts/lib/modules/Licensing.sol";
import { ShortString, ShortStrings } from "@openzeppelin/contracts/utils/ShortStrings.sol";

/// List of Protocol Term Ids (meaning the Licensing Module will have specific instructions
/// for these terms without the need of a decoder)
/// @dev must be < 32 bytes long, or they will blow up at some point
/// see https://docs.openzeppelin.com/contracts/4.x/api/utils#ShortStrings
library PIPLicensingTerms {
    using ShortStrings for *;

    string constant TERRITORY = "TERRITORY";
    string constant CHANNELS_OF_DISTRIBUTION = "CHANNELS_OF_DISTRIBUTION ";
    string constant EXPIRATION = "EXPIRATION";
    string constant REVOCABLE = "REVOCABLE";
    string constant ATTRIBUTION = "ATTRIBUTION";
    string constant DERIVATIVES = "DERIVATIVES";
    string constant CONTENT_STANDARDS = "CONTENT_STANDARDS";
    string constant COMMERCIAL_USE = "COMMERCIAL_USE";
    string constant GROSS_REVENUES = "GROSS_REVENUES";
    string constant LICENSE_FEE = "LICENSE_FEE";
    string constant SUBLICENSABLE = "SUBLICENSABLE";
    string constant TRANSFERABLE = "TRANSFERABLE";
    string constant CURRENCY = "CURRENCY";
    string constant PAYMENT_ADDRESS = "PAYMENT_ADDRESS";
    string constant GOVERNING_LAW = "GOVERNING_LAW";
    string constant ALTERNATIVE_DISPUTE_RESOLUTION =
        "ALTERNATIVE_DISPUTE_RESOLUTION";

    function getParamDefs()
        external
        pure
        returns (Licensing.ParamDefinition[] memory paramDefs)
    {
        paramDefs = new Licensing.ParamDefinition[](16);
        paramDefs[0] = Licensing.ParamDefinition(
            TERRITORY.toShortString(),
            Licensing.ParameterType.MultipleChoice
        );
        paramDefs[1] = Licensing.ParamDefinition(
            CHANNELS_OF_DISTRIBUTION.toShortString(),
            Licensing.ParameterType.MultipleChoice
        );
        paramDefs[2] = Licensing.ParamDefinition(
            EXPIRATION.toShortString(),
            Licensing.ParameterType.Number
        );
        paramDefs[3] = Licensing.ParamDefinition(
            REVOCABLE.toShortString(),
            Licensing.ParameterType.Bool
        );
        paramDefs[4] = Licensing.ParamDefinition(
            ATTRIBUTION.toShortString(),
            Licensing.ParameterType.Bool
        );
        paramDefs[5] = Licensing.ParamDefinition(
            DERIVATIVES.toShortString(),
            Licensing.ParameterType.MultipleChoice
        );
        paramDefs[6] = Licensing.ParamDefinition(
            CONTENT_STANDARDS.toShortString(),
            Licensing.ParameterType.MultipleChoice
        );
        paramDefs[7] = Licensing.ParamDefinition(
            COMMERCIAL_USE.toShortString(),
            Licensing.ParameterType.MultipleChoice
        );
        paramDefs[8] = Licensing.ParamDefinition(
            GROSS_REVENUES.toShortString(),
            Licensing.ParameterType.Number
        );
        paramDefs[9] = Licensing.ParamDefinition(
            LICENSE_FEE.toShortString(),
            Licensing.ParameterType.MultipleChoice
        );
        paramDefs[10] = Licensing.ParamDefinition(
            SUBLICENSABLE.toShortString(),
            Licensing.ParameterType.Bool
        );
        paramDefs[11] = Licensing.ParamDefinition(
            TRANSFERABLE.toShortString(),
            Licensing.ParameterType.Bool
        );
        paramDefs[12] = Licensing.ParamDefinition(
            CURRENCY.toShortString(),
            Licensing.ParameterType.Address
        );
        paramDefs[13] = Licensing.ParamDefinition(
            PAYMENT_ADDRESS.toShortString(),
            Licensing.ParameterType.Address
        );
        paramDefs[14] = Licensing.ParamDefinition(
            GOVERNING_LAW.toShortString(),
            Licensing.ParameterType.String
        );
        paramDefs[15] = Licensing.ParamDefinition(
            ALTERNATIVE_DISPUTE_RESOLUTION.toShortString(),
            Licensing.ParameterType.String
        );
    }
}
