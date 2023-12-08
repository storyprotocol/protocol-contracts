// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import { Errors } from "contracts/lib/Errors.sol";
import { BitMask } from "contracts/lib/BitMask.sol";
import { IPOrgController } from "contracts/ip-org/IPOrgController.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { MockERC721 } from "test/foundry/mocks/MockERC721.sol";

contract BitMaskHarness {

    function convertToMask(uint8[] calldata assetTypes) pure external returns (uint256) {
        return BitMask.convertToMask(assetTypes);
    }

    function isSet(uint256 mask, uint8 assetType) pure external returns (bool) {
        return BitMask.isSet(mask, assetType);
    }

}

contract BitMaskTest is Test {

    BitMaskHarness public checker;

    function setUp() public {
        checker = new BitMaskHarness();
    }

    function test_BitMask_convertToMask() public {
        for (uint8 i = 1; i <= 254; i++) {
            uint8[] memory assetTypes = new uint8[](i);
            uint256 resultMask;
            for (uint8 j = 1; j <= i; j++) {
                assetTypes[j-1] = uint8(j);
                resultMask |= 1 << (uint256(j) & 0xff);
            }
            uint256 mask = checker.convertToMask(assetTypes);
            assertEq(mask, resultMask);
        }
    }

    function test_BitMask_isSetOnMaskTrue() public {
        uint256 mask = 0;
        for (uint256 i = 0; i < 256; i++) {
            mask |= 1 << (i & 0xff);
        }
        for (uint256 i = 1; i < 256; i++) {
            assertTrue(checker.isSet(mask, uint8(i)));
        }
    }

    function test_BitMask_isSetOnMaskFalse() public {
        for (uint8 i = 1; i <= uint8(254); i++) {
            uint256 zeroMask;
            assertFalse(checker.isSet(zeroMask, i));
        }
    }
    
}