/* solhint-disable contract-name-camelcase, func-name-mixedcase, var-name-mixedcase */

// SPDX-License-Identifier: UNLICENSED
// See Story Protocol Alpha Agreement: https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import { FixedSet } from "contracts/utils/FixedSet.sol";
import { BitMask } from "contracts/lib/BitMask.sol";
import { Licensing } from "contracts/lib/modules/Licensing.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ShortStrings, ShortString } from "@openzeppelin/contracts/utils/ShortStrings.sol";

contract LicensingLibHarness {
		function exposed_statusToString(Licensing.LicenseStatus status_) external pure returns (string memory) {
				return Licensing._statusToString(status_);
		}

		function exposed_decodeMultipleChoice(
				bytes memory value,
        bytes memory availableChoices_
		) external pure returns (ShortString[] memory) {
				return Licensing._decodeMultipleChoice(value, availableChoices_);
		}

		function exposed_encodeMultipleChoice(
				uint8[] memory choiceIndexes_
		) external pure returns (bytes memory) {
				return Licensing._encodeMultipleChoice(choiceIndexes_);
		}

		function exposed_validateParamValue(
				Licensing.ParamDefinition memory paramDef_,
				bytes memory value_
		) external pure returns (bool) {
				return Licensing._validateParamValue(paramDef_, value_);
		}

		function exposed_getDecodedParamString(
				Licensing.ParamDefinition memory paramDef_,
				bytes memory value_
		) external pure returns (string memory) {
				return Licensing._getDecodedParamString(paramDef_, value_);
		}
}

contract LicensingLibTest is Test {
		using ShortStrings for *;

		LicensingLibHarness public checker;

		function setUp() public {
				checker = new LicensingLibHarness();
		}

		function test_LicensingLib_statusToString() public {
				assertEq(checker.exposed_statusToString(Licensing.LicenseStatus.Unset), "Unset");
				assertEq(checker.exposed_statusToString(Licensing.LicenseStatus.Active), "Active");
				assertEq(checker.exposed_statusToString(Licensing.LicenseStatus.PendingLicensorApproval), "Pending Licensor Approval");
				assertEq(checker.exposed_statusToString(Licensing.LicenseStatus.Revoked), "Revoked");
		}

		function test_LicensingLib_decodeMultipleChoice() public {
				ShortString[] memory choices = new ShortString[](3);
				choices[0] = "a".toShortString();
				choices[1] = "b".toShortString();
				choices[2] = "c".toShortString();
				bytes memory availableChoices = abi.encode(choices);
				bytes memory value = abi.encodePacked(uint256(1) << 1 | uint256(1) << 2);
				ShortString[] memory decoded = checker.exposed_decodeMultipleChoice(value, availableChoices);
				assertEq(decoded.length, 2);
				assertEq(decoded[0].toString(), "b");
				assertEq(decoded[1].toString(), "c");
		}

		function test_LicensingLib_encodeMultipleChoice() public {
				uint8[] memory choiceIndexes = new uint8[](2);
				choiceIndexes[0] = 2;
				choiceIndexes[1] = 1;
				bytes memory mask = checker.exposed_encodeMultipleChoice(choiceIndexes);
				assertEq(abi.decode(mask, (uint256)), uint256(1) << 1 | uint256(1) << 2);
		}

		function test_LicensingLib_validateParamValue() public {
				Licensing.ParamDefinition memory paramDef = Licensing.ParamDefinition(
            "def".toShortString(),
            Licensing.ParameterType.Bool,
            abi.encode(false),
            ""
        );
				assertTrue(checker.exposed_validateParamValue(paramDef, abi.encode(true)), "bool1");
				assertTrue(checker.exposed_validateParamValue(paramDef, abi.encode(false)), "bool2");
				assertTrue(checker.exposed_validateParamValue(paramDef, abi.encode(uint256(1))), "bool3");
				assertTrue(checker.exposed_validateParamValue(paramDef, abi.encode(address(0))), "bool4");
				vm.expectRevert();
				checker.exposed_validateParamValue(paramDef, abi.encode(""));

				paramDef = Licensing.ParamDefinition(
						"def".toShortString(),
						Licensing.ParameterType.Number,
						abi.encode(uint256(1)),
						""
				);
				assertTrue(checker.exposed_validateParamValue(paramDef, abi.encode(uint256(2))), "num1");
				assertTrue(checker.exposed_validateParamValue(paramDef, abi.encode(true)), "num2");
				assertFalse(checker.exposed_validateParamValue(paramDef, abi.encode(address(0))), "num3");
				// vm.expectRevert();
				// checker.exposed_validateParamValue(paramDef, abi.encode(""));

				paramDef = Licensing.ParamDefinition(
						"def".toShortString(),
						Licensing.ParameterType.Address,
						abi.encode(address(0x1)),
						""
				);
				assertFalse(checker.exposed_validateParamValue(paramDef, abi.encode(address(0x0))), "addr1");
				assertTrue(checker.exposed_validateParamValue(paramDef, abi.encode(address(0x1))), "addr2");
				assertTrue(checker.exposed_validateParamValue(paramDef, abi.encode(true)), "addr3");
				assertFalse(checker.exposed_validateParamValue(paramDef, abi.encode(uint256(0))), "addr4");
				assertTrue(checker.exposed_validateParamValue(paramDef, abi.encode("")), "addr5");

				paramDef = Licensing.ParamDefinition(
						"def".toShortString(),
						Licensing.ParameterType.String,
						abi.encode("a"),
						""
				);
				assertTrue(checker.exposed_validateParamValue(paramDef, abi.encode("b")), "string1");
				assertTrue(checker.exposed_validateParamValue(paramDef, abi.encode(uint256(0))), "string2");
				assertFalse(checker.exposed_validateParamValue(paramDef, abi.encode("")), "string3");
				vm.expectRevert();
				checker.exposed_validateParamValue(paramDef, abi.encode(true));

				ShortString[] memory ssa = new ShortString[](3);
				ssa[0] = "a".toShortString();
				ssa[1] = "b".toShortString();
				ssa[2] = "c".toShortString();
				paramDef = Licensing.ParamDefinition(
						"def".toShortString(),
						Licensing.ParameterType.ShortStringArray,
						abi.encodePacked(ssa),
						""
				);
				assertFalse(checker.exposed_validateParamValue(paramDef, abi.encode("")));
				assertFalse(checker.exposed_validateParamValue(paramDef, abi.encode(new ShortString[](0))));
		}

		function test_LicensingLib_getDecodedParamString() public {
				Licensing.ParamDefinition memory paramDef = Licensing.ParamDefinition(
            "def".toShortString(),
            Licensing.ParameterType.Bool,
            abi.encode(false),
            ""
        );
				assertEq(checker.exposed_getDecodedParamString(paramDef, abi.encode(true)), "true");
				assertEq(checker.exposed_getDecodedParamString(paramDef, abi.encode(false)), "false");

				paramDef = Licensing.ParamDefinition(
						"def".toShortString(),
						Licensing.ParameterType.Number,
						abi.encode(uint256(1)),
						""
				);
				assertEq(checker.exposed_getDecodedParamString(paramDef, abi.encode(uint256(2))), "2");
				assertEq(checker.exposed_getDecodedParamString(paramDef, abi.encode(uint256(0))), "0");

				paramDef = Licensing.ParamDefinition(
						"def".toShortString(),
						Licensing.ParameterType.String,
						abi.encode(""),
						""
				);
				assertEq(checker.exposed_getDecodedParamString(paramDef, abi.encode("a")), "a");
				assertEq(checker.exposed_getDecodedParamString(paramDef, abi.encode("")), "");

				paramDef = Licensing.ParamDefinition(
						"def".toShortString(),
						Licensing.ParameterType.Address,
						abi.encode(address(0x1)),
						""
				);
				assertEq(checker.exposed_getDecodedParamString(paramDef, abi.encode(address(0x0))), "0x0000000000000000000000000000000000000000");
				assertEq(checker.exposed_getDecodedParamString(paramDef, abi.encode(address(0xf))), "0x000000000000000000000000000000000000000f");
		}
}