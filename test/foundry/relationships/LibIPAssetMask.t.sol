// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import { IPAssetRegistryFactory } from "contracts/ip-assets/IPAssetRegistryFactory.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { LibIPAssetMask } from "contracts/modules/relationships/LibIPAssetMask.sol";
import { IPAsset } from "contracts/lib/IPAsset.sol";
import { FranchiseRegistry } from "contracts/FranchiseRegistry.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { MockERC721 } from "../mocks/MockERC721.sol";

contract LibIPAssetMaskHarness {

    function convertToMask(IPAsset.IPAssetType[] calldata ipAssets, bool allowsExternal) pure external returns (uint256) {
        return LibIPAssetMask._convertToMask(ipAssets, allowsExternal);
    }

    function convertFromMask(uint256 mask) pure external returns (IPAsset.IPAssetType[] memory, bool) {
        return LibIPAssetMask._convertFromMask(mask);
    }

    function supportsIPAssetType(uint256 mask, uint8 assetType) pure external returns (bool) {
        return LibIPAssetMask._supportsIPAssetType(mask, assetType);
    }

    function checkRelationshipNode(bool isAssetRegistry, uint256 assetId, uint256 assetTypeMask) external pure returns (bool result) {
        return LibIPAssetMask._checkRelationshipNode(isAssetRegistry, assetId, assetTypeMask);
    }
}

contract LibIPAssetMaskHarnessTest is Test {

    LibIPAssetMaskHarness public checker;

    error InvalidIPAssetArray();

    function setUp() public {
        checker = new LibIPAssetMaskHarness();
    }

    function test_convertToMaskWithoutExternal() public {
        for (uint8 i = 1; i <= uint8(IPAsset.IPAssetType.ITEM); i++) {
            IPAsset.IPAssetType[] memory ipAssets = new IPAsset.IPAssetType[](i);
            uint256 resultMask;
            for (uint8 j = 1; j <= i; j++) {
                ipAssets[j-1] = IPAsset.IPAssetType(j);
                resultMask |= 1 << (uint256(IPAsset.IPAssetType(j)) & 0xff);
            }
            uint256 mask = checker.convertToMask(ipAssets, false);
            assertEq(mask, resultMask);
        }
    }

    function test_convertToMaskWithExternal() public {
        for (uint8 i = 1; i <= uint8(IPAsset.IPAssetType.ITEM); i++) {
            IPAsset.IPAssetType[] memory ipAssets = new IPAsset.IPAssetType[](i);
            uint256 resultMask;
            for (uint8 j = 1; j <= i; j++) {
                ipAssets[j-1] = IPAsset.IPAssetType(j);
                resultMask |= 1 << (uint256(IPAsset.IPAssetType(j)) & 0xff);
            }
            resultMask |= uint256(IPAsset.EXTERNAL_ASSET) << 248;
            uint256 mask = checker.convertToMask(ipAssets, true);
            assertEq(mask, resultMask);
        }
    }

    function test_revert_convertToMaskWithExternal_ifEmptyArray() public {
        IPAsset.IPAssetType[] memory ipAssets = new IPAsset.IPAssetType[](0);
        vm.expectRevert(Errors.IPAsset_InvalidIPAssetArray.selector);
        checker.convertToMask(ipAssets, false);
    }

    function test_revert_convertToMaskWithExterna_ifZeroRow() public {
        IPAsset.IPAssetType[] memory ipAssets = new IPAsset.IPAssetType[](1);
        ipAssets[0] = IPAsset.IPAssetType(0);
        vm.expectRevert(Errors.IPAsset_InvalidIPAssetArray.selector);
        checker.convertToMask(ipAssets, false);
    }
    
}

contract LibIPAssetMaskConvertFromMaskTest is Test {

    LibIPAssetMaskHarness public checker;

    error InvalidIPAssetArray();
    IPAsset.IPAssetType[] assets;

    function setUp() public {
        checker = new LibIPAssetMaskHarness();
    }

    function test_convertFromMask() public {
        IPAsset.IPAssetType[] memory result;
        bool supportsExternal;
        uint256 mask = 0;
        for (uint8 i = 1; i <= uint8(IPAsset.IPAssetType.ITEM); i++) {
            mask |= 1 << (uint256(IPAsset.IPAssetType(i)) & 0xff);
            assets.push(IPAsset.IPAssetType(i));
            (result, supportsExternal) = checker.convertFromMask(mask);
            assertFalse(supportsExternal);
            for (uint8 j = 0; j < assets.length; j++) {
                assertEq(uint8(result[j]), uint8(assets[j]));
            }
        }
        mask |= uint256(IPAsset.EXTERNAL_ASSET) << 248;
        (result, supportsExternal) = checker.convertFromMask(mask);
        assertTrue(supportsExternal);
        for (uint8 j = 0; j < assets.length; j++) {
            assertEq(uint8(result[j]), uint8(assets[j]));
        }
    }

}

contract LibIPAssetMaskSupportsAssetTypeTest is Test {

    LibIPAssetMaskHarness public checker;

    error InvalidIPAssetArray();

    function setUp() public {
        checker = new LibIPAssetMaskHarness();
    }

    function test_supportsIPAssetType_true() public {
        uint256 mask = 0;
        for (uint8 i = 1; i <= uint8(IPAsset.IPAssetType.ITEM); i++) {
            mask |= 1 << (uint256(IPAsset.IPAssetType(i)) & 0xff);
        }
        mask |= uint256(IPAsset.EXTERNAL_ASSET) << 248;
        for (uint8 i = 1; i <= uint8(IPAsset.IPAssetType.ITEM); i++) {
            assertTrue(checker.supportsIPAssetType(mask, i));
        }
        assertTrue(checker.supportsIPAssetType(mask, type(uint8).max));
    }

    function test_supportIPAssetType_false() public {
        uint256 zeroMask;
        for (uint8 i = 1; i <= uint8(IPAsset.IPAssetType.ITEM); i++) {
            assertFalse(checker.supportsIPAssetType(zeroMask, i));
        }
        assertFalse(checker.supportsIPAssetType(zeroMask, type(uint8).max));
    }
    
}



contract LibIPAssetMaskNodesTest is Test {

    LibIPAssetMaskHarness public checker;
    MockERC721 public collection;
    address public owner = address(0x1);

    error InvalidIPAssetArray();

    function setUp() public {
        checker = new LibIPAssetMaskHarness();
        collection = new MockERC721();
    }

    function test_checkRelationshipNode_ipAsset_true() public {
        uint256 tokenId = IPAsset._zeroId(IPAsset.IPAssetType(1)) + 1;
        collection.mint(owner, tokenId);
        uint256 mask = 1 << (uint256(IPAsset.IPAssetType(1)) & 0xff);
        bool result = checker.checkRelationshipNode(true, tokenId, mask);
        assertTrue(result);
    }

    function test_checkRelationshipNode_ipAsset_false() public {
        uint256 tokenId = IPAsset._zeroId(IPAsset.IPAssetType(1)) + 1;
        collection.mint(owner, tokenId);
        uint256 mask = 1 << (uint256(IPAsset.IPAssetType(2)) & 0xff);
        bool result = checker.checkRelationshipNode(true, tokenId, mask);
        assertFalse(result);
    }

    function test_checkRelationshipNode_external_true() public {
        uint256 tokenId = IPAsset._zeroId(IPAsset.IPAssetType(1)) + 1;
        collection.mint(owner, tokenId);
        uint256 mask = 1 << (uint256(IPAsset.EXTERNAL_ASSET) & 0xff);
        bool result = checker.checkRelationshipNode(false, tokenId, mask);
        assertTrue(result);
    }

    
}
