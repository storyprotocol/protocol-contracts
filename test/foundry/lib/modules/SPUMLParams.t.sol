/* solhint-disable contract-name-camelcase, func-name-mixedcase, var-name-mixedcase */
// SPDX-License-Identifier: UNLICENSED
// See Story Protocol Alpha Agreement: https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { Licensing } from "contracts/lib/modules/Licensing.sol";
import { SPUMLParams } from "contracts/lib/modules/SPUMLParams.sol";
import { ShortString, ShortStrings } from "@openzeppelin/contracts/utils/ShortStrings.sol";

contract SPUMLParamsHarness {
    function exposedgetDerivativeChoices() external pure returns (ShortString[] memory) {
        return SPUMLParams.getDerivativeChoices();
    }

    function exposedgetParamDefs() external pure returns (Licensing.ParamDefinition[] memory paramDefs) {
        return SPUMLParams.getParamDefs();
    }
}

contract SPUMLParamsTest is Test {
    using ShortStrings for *;

    SPUMLParamsHarness public checker;

    function setUp() public {
        checker = new SPUMLParamsHarness();
    }

    function test_SPUMLParamsgetDerivativeChoices() public {
        ShortString[] memory choices = checker.exposedgetDerivativeChoices();
        assertEq(choices.length, 3);
        assertEq(choices[0].toString(), SPUMLParams.ALLOWED_WITH_APPROVAL);
        assertEq(choices[1].toString(), SPUMLParams.ALLOWED_WITH_RECIPROCAL_LICENSE);
        assertEq(choices[2].toString(), SPUMLParams.ALLOWED_WITH_ATTRIBUTION);
    }

    function test_SPUMLParamsgetParamDefs()
        public
    {
        Licensing.ParamDefinition[] memory paramDefs = new Licensing.ParamDefinition[](4);
        Licensing.ParamDefinition[] memory actual = checker.exposedgetParamDefs();

        paramDefs[0] = Licensing.ParamDefinition(
            SPUMLParams.CHANNELS_OF_DISTRIBUTION.toShortString(),
            Licensing.ParameterType.ShortStringArray,
            "",
            ""
        );
        paramDefs[1] = Licensing.ParamDefinition(
            SPUMLParams.ATTRIBUTION.toShortString(),
            Licensing.ParameterType.Bool,
            abi.encode(false),
            ""
        );
        paramDefs[2] = Licensing.ParamDefinition(
            SPUMLParams.DERIVATIVES_ALLOWED.toShortString(),
            Licensing.ParameterType.Bool,
            abi.encode(false),
            ""
        );
        paramDefs[3] = Licensing.ParamDefinition(
            SPUMLParams.DERIVATIVES_ALLOWED_OPTIONS.toShortString(),
            Licensing.ParameterType.MultipleChoice,
            "",
            abi.encode(checker.exposedgetDerivativeChoices())
        );

        assertEq(actual.length, paramDefs.length);
        for (uint256 i = 0; i < actual.length; ++i) {
            assertEq(actual[i].tag.toString(), paramDefs[i].tag.toString());
            assertEq(uint8(actual[i].paramType), uint8(paramDefs[i].paramType));
            assertEq(actual[i].defaultValue, paramDefs[i].defaultValue);
            assertEq(actual[i].availableChoices, paramDefs[i].availableChoices);
        }
    }
}
