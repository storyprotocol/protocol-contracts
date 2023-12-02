/* solhint-disable contract-name-camelcase, func-name-mixedcase */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ShortString, ShortStrings } from "@openzeppelin/contracts/utils/ShortStrings.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { FixedSet } from "contracts/utils/FixedSet.sol";
import { Test } from "forge-std/Test.sol";

/**
 * @notice A harness contract for testing `FixedSet`.
 * @dev This is required for foundry coverage to work with libraries.
 */
contract FixedSetHarness {
    using ShortStrings for *;
    FixedSet.Bytes32Set internal b32Set;
    FixedSet.ShortStringSet internal ssSet;
    FixedSet.AddressSet internal addrSet;
    FixedSet.UintSet internal uintSet;

    // using FixedSet for FixedSet.Bytes32Set;
    // using FixedSet for FixedSet.ShortStringSet;
    // using FixedSet for FixedSet.AddressSet;
    // using FixedSet for FixedSet.UintSet;

    function add(bytes32 value) external returns (bool) {
      return FixedSet.add(b32Set, value);
    }

    function addShortStringSet(ShortString value) external returns (bool) {
      return FixedSet.add(ssSet, value);
    }

    function add(address value) external returns (bool) {
      return FixedSet.add(addrSet, value);
    }

    function add(uint256 value) external returns (bool) {
      return FixedSet.add(uintSet, value);
    }

    function contains(bytes32 value) external view returns (bool) {
      return FixedSet.contains(b32Set, value);
    }

    function containsShortStringSet(ShortString value) external view returns (bool) {
      return FixedSet.contains(ssSet, value);
    }

    function contains(address value) external view returns (bool) {
      return FixedSet.contains(addrSet, value);
    }

    function contains(uint256 value) external view returns (bool) {
      return FixedSet.contains(uintSet, value);
    }

    function lengthBytes32Set() external view returns (uint256) {
      return FixedSet.length(b32Set);
    }

    function lengthShortStringSet() external view returns (uint256) {
      return FixedSet.length(ssSet);
    }

    function lengthAddressSet() external view returns (uint256) {
      return FixedSet.length(addrSet);
    }

    function lengthUintSet() external view returns (uint256) {
      return FixedSet.length(uintSet);
    }

    function atBytes32Set(uint256 index) external view returns (bytes32) {
      return FixedSet.at(b32Set, index);
    }

    function atShortStringSet(uint256 index) external view returns (ShortString) {
      return FixedSet.at(ssSet, index);
    }

    function atAddressSet(uint256 index) external view returns (address) {
      return FixedSet.at(addrSet, index);
    }

    function atUintSet(uint256 index) external view returns (uint256) {
      return FixedSet.at(uintSet, index);
    }

    function indexOf(bytes32 value) external view returns (uint256) {
      return FixedSet.indexOf(b32Set, value);
    }

    function indexOfShortStringSet(ShortString value) external view returns (uint256) {
      return FixedSet.indexOf(ssSet, value);
    }

    function indexOf(address value) external view returns (uint256) {
      return FixedSet.indexOf(addrSet, value);
    }

    function indexOf(uint256 value) external view returns (uint256) {
      return FixedSet.indexOf(uintSet, value);
    }

    function valuesBytes32Set() external view returns (bytes32[] memory) {
      return FixedSet.values(b32Set);
    }

    function valuesShortStringSet() external view returns (ShortString[] memory) {
      return FixedSet.values(ssSet);
    }

    function valuesAddressSet() external view returns (address[] memory) {
      return FixedSet.values(addrSet);
    }

    function valuesUintSet() external view returns (uint256[] memory) {
      return FixedSet.values(uintSet);
    }
}

contract FixedSetLibTest is Test {
    using ShortStrings for *;

    FixedSetHarness internal fset;

    function setUp() public {
        fset = new FixedSetHarness();
    }

    function test_fixedSet_Bytes32Set_basicOperations() public {
        bytes32[] memory bytes32s = new bytes32[](4);
        bytes32s[0] = bytes32("a");
        bytes32s[1] = bytes32("b");
        bytes32s[2] = bytes32("c");
        bytes32s[3] = bytes32("d");

        for (uint256 i = 0; i < bytes32s.length; ++i) {
            assertTrue(fset.add(bytes32s[i]));
            assertFalse(fset.add(bytes32s[i]));
        }

        assertEq(fset.lengthBytes32Set(), bytes32s.length);

        for (uint256 i = 0; i < bytes32s.length; ++i) {
            assertEq(fset.atBytes32Set(i), bytes32s[i]);
            assertEq(fset.indexOf(bytes32s[i]), i);
            assertTrue(fset.contains(bytes32s[i]));
        }

        assertEq(fset.indexOf(bytes32("e")), FixedSet.INDEX_NOT_FOUND);
        assertFalse(fset.contains(bytes32("e")));

        bytes32[] memory values = fset.valuesBytes32Set();
        assertEq(values.length, bytes32s.length);
        for (uint256 i = 0; i < bytes32s.length; ++i) {
            assertEq(values[i], bytes32s[i]);
        }
    }

    function test_fixedSet_ShortStringSet_basicOperations() public {
        ShortString[] memory strings = new ShortString[](4);
        strings[0] = "a".toShortString();
        strings[1] = "b".toShortString();
        strings[2] = "c".toShortString();
        strings[3] = "d".toShortString();

        for (uint256 i = 0; i < strings.length; ++i) {
            assertTrue(fset.addShortStringSet(strings[i]));
            assertFalse(fset.addShortStringSet(strings[i]));
        }

        assertEq(fset.lengthShortStringSet(), strings.length);

        for (uint256 i = 0; i < strings.length; ++i) {
            assertTrue(Strings.equal(fset.atShortStringSet(i).toString(), strings[i].toString()));
            assertEq(fset.indexOfShortStringSet(strings[i]), i);
            assertTrue(fset.containsShortStringSet(strings[i]));
        }

        assertEq(fset.indexOfShortStringSet("e".toShortString()), FixedSet.INDEX_NOT_FOUND);
        assertFalse(fset.containsShortStringSet("e".toShortString()));

        ShortString[] memory values = fset.valuesShortStringSet();
        assertEq(values.length, strings.length);
        for (uint256 i = 0; i < strings.length; ++i) {
            assertTrue(Strings.equal(values[i].toString(), strings[i].toString()));
        }
    }

    function test_fixedSet_AddressSet_basicOperations() public {
        address[] memory addresses = new address[](4);
        addresses[0] = address(1);
        addresses[1] = address(2);
        addresses[2] = address(3);
        addresses[3] = address(4);

        for (uint256 i = 0; i < addresses.length; ++i) {
            fset.add(addresses[i]);
        }

        assertEq(fset.lengthAddressSet(), addresses.length);

        for (uint256 i = 0; i < addresses.length; ++i) {
            assertEq(fset.atAddressSet(i), addresses[i]);
            assertEq(fset.indexOf(addresses[i]), i);
            assertTrue(fset.contains(addresses[i]));
        }

        assertEq(fset.indexOf(address(5)), FixedSet.INDEX_NOT_FOUND);
        assertFalse(fset.contains(address(5)));

        address[] memory values = fset.valuesAddressSet();
        assertEq(values.length, addresses.length);
        for (uint256 i = 0; i < addresses.length; ++i) {
            assertEq(values[i], addresses[i]);
        }
    }

    function test_fixedSet_UintSet_basicOperations() public {
        uint256[] memory uints = new uint256[](4);
        uints[0] = 1;
        uints[1] = 2;
        uints[2] = 3;
        uints[3] = 4;

        for (uint256 i = 0; i < uints.length; ++i) {
            assertTrue(fset.add(uints[i]));
            assertFalse(fset.add(uints[i]));
        }

        assertEq(fset.lengthUintSet(), uints.length);

        for (uint256 i = 0; i < uints.length; ++i) {
            assertEq(fset.atUintSet(i), uints[i]);
            assertEq(fset.indexOf(uints[i]), i);
            assertTrue(fset.contains(uints[i]));
        }

        assertEq(fset.indexOf(5), FixedSet.INDEX_NOT_FOUND);
        assertFalse(fset.contains(5));

        uint256[] memory values = fset.valuesUintSet();
        assertEq(values.length, uints.length);
        for (uint256 i = 0; i < uints.length; ++i) {
            assertEq(values[i], uints[i]);
        }
    }
}
