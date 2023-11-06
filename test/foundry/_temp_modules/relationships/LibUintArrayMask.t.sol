// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import { Errors } from "contracts/lib/Errors.sol";
import { LibUintArrayMask } from "contracts/modules/relationships/LibUintArrayMask.sol";
import { IPOrgFactory } from "contracts/ip-org/IPOrgFactory.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { MockERC721 } from "test/foundry/mocks/MockERC721.sol";

contract LibUintArrayMaskHarness {

    function convertToMask(uint8[] calldata assetTypes) pure external returns (uint256) {
        return LibUintArrayMask._convertToMask(assetTypes);
    }

    function isAssetTypeOnMask(uint256 mask, uint8 assetType) pure external returns (bool) {
        return LibUintArrayMask._isAssetTypeOnMask(mask, assetType);
    }

}

contract LibUintArrayMaskHarnessTest is Test {

    LibUintArrayMaskHarness public checker;

    function setUp() public {
        checker = new LibUintArrayMaskHarness();
    }

    function test_LibUintArrayMask_convertToMask() public {
        for (uint8 i = 1; i <= 254; i++) {
            uint8[] memory assetTypes = new uint8[](i);
            uint256 resultMask;
            for (uint8 j = 1; j <= i; j++) {
                assetTypes[j-1] = uint8(j);
                resultMask |= 1 << (uint256(j) & 0xff);
            }
            uint256 mask = checker.convertToMask(assetTypes);
            console.log(mask);
            assertEq(mask, resultMask);
        }
    }

    function test_LibUintArrayMask_revert_EmptyArray() public {
        uint8[] memory ipAssets = new uint8[](0);
        vm.expectRevert(Errors.LibUintArrayMask_EmptyArray.selector);
        checker.convertToMask(ipAssets);
    }

    function test_LibUintArrayMask_revert_UndefinedArrayElement() public {
        uint8[] memory ipAssets = new uint8[](1);
        ipAssets[0] = 0;
        vm.expectRevert(Errors.LibUintArrayMask_UndefinedArrayElement.selector);
        checker.convertToMask(ipAssets);
    }
    
}



contract LibIPAssetMaskChecksTest is Test {

    LibUintArrayMaskHarness public checker;

    error InvalidIPAssetArray();

    function setUp() public {
        checker = new LibUintArrayMaskHarness();
    }

    function test_LibUintArrayMask_isAssetTypeOnMaskTrue() public {
        uint256 mask = 0;
        for (uint8 i = 1; i <= uint8(254); i++) {
            mask |= 1 << (uint256(i) & 0xff);
        }
        for (uint8 i = 1; i <= uint8(254); i++) {
            assertTrue(checker.isAssetTypeOnMask(mask, i));
        }
    }

    function test_LibUintArrayMask_isAssetTypeOnMaskFalse() public {
        uint256 zeroMask;
        for (uint8 i = 1; i <= uint8(254); i++) {
            assertFalse(checker.isAssetTypeOnMask(zeroMask, i));
        }
    }
    
}
