// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @notice Based on OpenZeppelin's BitMap, this library is used to encode a set of indexes in a compact way.
 * Instead of using a storage type like OZ, where they use a mapping(uint256 => uint256) for large numbers of values,
 * this library limts it to a 256 values in a single uint256.
 */
library BitMask {
    /// Returns whether the bit at `index` is set.
    function isSet(uint256 mask_, uint8 index_) internal pure returns (bool) {
        uint256 indexMask = 1 << (index_ & 0xff);
        return mask_ & indexMask != 0;
    }

    /// Sets the bit at `index` to the boolean `value`.
    function setTo(uint256 mask_, uint256 index_, bool value_) internal pure returns (uint256) {
        if (value_) {
            return set(mask_, index_);
        } else {
            return unset(mask_, index_);
        }
    }

    /// Sets the bit at `index`.
    function set(uint256 mask_, uint256 index_) internal pure returns (uint256) {
        uint256 indexMask = 1 << (index_ & 0xff);
        return mask_ |= indexMask;
    }

    /// Unsets the bit at `index`.
    function unset(uint256 mask_, uint256 index_) internal pure returns (uint256) {
        uint256 indexMask = 1 << (index_ & 0xff);
        return mask_ &= ~indexMask;
    }

    /// Gets the uint8 from the bitmask as an array
    function getSetIndexes(uint256 mask_) internal pure returns (uint8[] memory) {
        // Count the number of set bits to allocate the array size
        uint256 count;
        for (uint8 i = 0; i < 255; ++i) {
            if (isSet(mask_, i)) {
                ++count;
            }
        }
        uint8[] memory setBitIndexes = new uint8[](count);
        // Fill the array with indices of set bits
        uint256 index = 0;
        for (uint8 i = 0; i < 255; ++i) {
            if (isSet(mask_, i)) {
                setBitIndexes[index] = i;
                ++index;
            }
        }
        return setBitIndexes;
    }

    /// Converts an array of uint8 to a bit mask
    function convertToMask(uint8[] memory indexes_) internal pure returns (uint256) {
        uint256 mask = 0;
        for (uint256 i = 0; i < indexes_.length; ) {
            mask |= 1 << (uint256(indexes_[i]) & 0xff);
            unchecked {
                i++;
            }
        }
        return mask;
    }
}
