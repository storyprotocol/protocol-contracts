// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ShortString, ShortStrings } from "@openzeppelin/contracts/utils/ShortStrings.sol";

/// @title FixedSet Library
/// @notice Fork of OZ's set data structures library with the following changs:
/// - Values cannot be removed from the set for order preservation
/// - The library allows obtaining indexes of values
/// - Adds ShortString as a data type
library FixedSet {
    using ShortStrings for *;

    uint256 internal constant INDEX_NOT_FOUND = type(uint256).max;

    /// @notice Data structure for composing a fixed set.
    struct Set {
        // Array for storing values within the fixed set.
        bytes32[] _values;
        // One-based index of the set value (0 is a sentinel valu).
        mapping(bytes32 => uint256) _indexes;
    }

    /// @dev Adds a value to a set.
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // Value is stored at values.length due to one-indexing.
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /// @dev Checks whether a value is contained in the set.
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /// @dev Returns the length of the set.
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /// @dev Returns the index of a value within the set.
    function _indexOf(Set storage set, bytes32 value) private view returns (uint256) {
        uint256 index = set._indexes[value];
        return index == 0 ? INDEX_NOT_FOUND : index - 1;
    }

    /// @dev Returns the value stored at the one-indexed positioned within the set.
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /// @dev Returns the entire fixed set as a bytes32-array.
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    ////////////////////////////////////////////////////////////////////////////
    //                            Bytes32Set                                  //
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Struct for composing fixed sets of bytes32 objects.
    struct Bytes32Set {
        Set _inner;
    }

    /// @dev Adds a value to the bytes32 set.
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /// @dev Checks whether a bytes32 set contains a value.
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /// @dev Gets the length of the bytes32 set.
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /// @dev Gets the value stored at the one-indexed position within the set.
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /// @dev Returns the one-indexed position of the value within the set.
    function indexOf(Bytes32Set storage set, bytes32 value) internal view returns (uint256) {
        return _indexOf(set._inner, value);
    }

    /// @dev Returns the entire set of bytes32 objects as an array.
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    ////////////////////////////////////////////////////////////////////////////
    //                            ShortStringSet                               //
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Fixed set data structure for representing SortStrings.
    struct ShortStringSet {
        Set _inner;
    }

    /// @dev Adds a value to the ShortString data set.
    function add(ShortStringSet storage set, ShortString value) internal returns (bool) {
        return _add(set._inner, ShortString.unwrap(value));
    }

    /// @dev Checks whether a ShortString set contains a value.
    function contains(ShortStringSet storage set, ShortString value) internal view returns (bool) {
        return _contains(set._inner, ShortString.unwrap(value));
    }

    /// @dev Returns the length of the ShortString set.
    function length(ShortStringSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /// @dev Returns the value stored at the one-indexed position in the set.
    function at(ShortStringSet storage set, uint256 index) internal view returns (ShortString) {
        return ShortString.wrap(_at(set._inner, index));
    }

    /// @dev Returns the index of the value within the ShortString set.
    function indexOf(ShortStringSet storage set, ShortString value) internal view returns (uint256) {
        return _indexOf(set._inner, ShortString.unwrap(value));
    }

    /// @dev Returns the entire ShortString data set.
    function values(ShortStringSet storage set) internal view returns (ShortString[] memory) {
        bytes32[] memory store = _values(set._inner);
        ShortString[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    ////////////////////////////////////////////////////////////////////////////
    //                            AddressSet                                  //
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Fixed set data structure for representing addresses.
    struct AddressSet {
        Set _inner;
    }

    /// @dev Adds a value to the fixed address set.
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /// @dev Checks whether a fixed address set contains a value.
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /// @dev Returns the length of the fixed address set.
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /// @dev Returns the value stored at the one-indexed position in the set.
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /// @dev Gets the index of an address within the fixed set.
    function indexOf(AddressSet storage set, address value) internal view returns (uint256) {
        return _indexOf(set._inner, bytes32(uint256(uint160(value))));
    }

    /// @dev Returns the entire suite of addresses stored in the set.
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    ////////////////////////////////////////////////////////////////////////////
    //                            UintSet                                     //
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Fixed set data structure for storing uint256 numbers.
    struct UintSet {
        Set _inner;
    }

    /// @dev Adds a uint256 value into the fixed set.
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /// @dev Checks whether the fixed set contains a uint256 value.
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /// @dev Returns the length of the uint256 set.
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /// @dev Returns the value stored at a one-indexed position within the set.
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /// @dev Returns the index of a uint256 value within the set.
    function indexOf(UintSet storage set, uint256 value) internal view returns (uint256) {
        return _indexOf(set._inner, bytes32(value));
    }

    /// @dev Returns the entire suite of uint256 values within the set.
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}
