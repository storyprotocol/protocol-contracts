// SPDX-License-Identifier: UNLICENSED
// See https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.19;

import { Licensing } from "contracts/lib/modules/Licensing.sol";
import { ShortString, ShortStrings } from "@openzeppelin/contracts/utils/ShortStrings.sol";

/// @title SPUMLParams Library
/// Defines the parameters for the SPUML license.
/// See: https://github.com/storyprotocol/protocol-contracts/blob/main/SPUML-v1.pdf
/// @dev must be < 32 bytes long, or they will blow up at some point
/// see https://docs.openzeppelin.com/contracts/4.x/api/utils#ShortStrings
library SPUMLParams {
    using ShortStrings for *;

    string public constant FRAMEWORK_ID = "SPUML-1.0";
    ////////////////////////////////////////////////////////////////////////////
    //                               Parameters                               //
    ////////////////////////////////////////////////////////////////////////////
    /// Sets allowed channels of distribution for the IPA
    string public constant CHANNELS_OF_DISTRIBUTION = "Channels-Of-Distribution";
    /// Sets whether attribution is required in reproductions of the IPA
    string public constant ATTRIBUTION = "Attribution";
    /// Sets whether derivatives are allowed for the IPA
    string public constant DERIVATIVES_ALLOWED = "Derivatives-Allowed";
    /// Sets the allowed derivative conditions for the IPA
    string public constant DERIVATIVES_ALLOWED_OPTIONS = "Derivatives-Allowed-Options";

    ////////////////////////////////////////////////////////////////////////////
    //                       Derivative Options                               //
    ////////////////////////////////////////////////////////////////////////////
    /// Licensor must activate license before linking with IPA
    string public constant ALLOWED_WITH_APPROVAL = "Allowed-With-Approval";
    uint8 public constant ALLOWED_WITH_APPROVAL_INDEX = 0;
    /// Licensee must license derivative under same terms. No licensor restrictions
    string public constant ALLOWED_WITH_RECIPROCAL_LICENSE = "Allowed-Reciprocal-License";
    uint8 public constant ALLOWED_WITH_RECIPROCAL_LICENSE_INDEX = 1;
    /// Licensee must attribute licensor when using derivative
    string public constant ALLOWED_WITH_ATTRIBUTION = "Allowed-With-Attribution";
    uint8 public constant ALLOWED_WITH_ATTRIBUTION_INDEX = 2;

    // On beta version
    // Parameters:
    // string constant CONTENT_STANDARDS = "Content-Standards";
    // string constant DERIVATIVES = "Derivatives";
    // string constant TERRITORY = "Territory";
    // string constant REVOCABLE = "Revocable";
    // string constant COMMERCIAL_USE = "Commercial-Use";
    // string constant GROSS_REVENUES = "Gross-Revenues";
    // string constant LICENSE_FEE = "License-Fee";
    // string constant SUBLICENSABLE = "Sublicensable";
    // string constant TRANSFERABLE = "Transferable";
    // string constant CURRENCY = "Currency";
    // string constant PAYMENT_ADDRESS = "Payment-Address";
    // string constant GOVERNING_LAW = "Governing-Law";
    // string constant EXPIRATION = "Expiration";
    // string constant ALTERNATIVE_DISPUTE_RESOLUTION =
    //    "Alternative-Dispute-Resolution";
    // Derivative options:
    // string constant ALLOWED_WITH_REVENUE_SHARE = "Allowed-With-Revenue-Share";
    // string constant ALLOWED_WITH_REVENUE_CEILING = "Allowed-With-Revenue-Ceiling";
    // string constant DERIVATIVES_ALLOWED_TAG_AMOUNT = "Derivatives-Allowed-Tag-Amount";

    /// @notice Returns the options for the derivative allowed parameter
    function getDerivativeChoices() internal pure returns (ShortString[] memory) {
        ShortString[] memory choices = new ShortString[](3);
        choices[0] = ALLOWED_WITH_APPROVAL.toShortString();
        choices[1] = ALLOWED_WITH_RECIPROCAL_LICENSE.toShortString();
        choices[2] = ALLOWED_WITH_ATTRIBUTION.toShortString();
        return choices;
    }

    /// @notice Returns the parameter definitions for the SPUML license
    function getParamDefs() internal pure returns (Licensing.ParamDefinition[] memory paramDefs) {
        paramDefs = new Licensing.ParamDefinition[](4);
        paramDefs[0] = Licensing.ParamDefinition(
            CHANNELS_OF_DISTRIBUTION.toShortString(),
            Licensing.ParameterType.ShortStringArray,
            "",
            ""
        );
        paramDefs[1] = Licensing.ParamDefinition(
            ATTRIBUTION.toShortString(),
            Licensing.ParameterType.Bool,
            abi.encode(false),
            ""
        );
        paramDefs[2] = Licensing.ParamDefinition(
            DERIVATIVES_ALLOWED.toShortString(),
            Licensing.ParameterType.Bool,
            abi.encode(false),
            ""
        );
        paramDefs[3] = Licensing.ParamDefinition(
            DERIVATIVES_ALLOWED_OPTIONS.toShortString(),
            Licensing.ParameterType.MultipleChoice,
            "", // Since this is dependent on the above, default is unset
            abi.encode(getDerivativeChoices())
        );
    }
}
