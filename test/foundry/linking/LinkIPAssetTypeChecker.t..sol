// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import { IPAssetRegistryFactory } from "contracts/ip-assets/IPAssetRegistryFactory.sol";
import { LinkIPAssetTypeChecker } from "contracts/modules/linking/LinkIPAssetTypeChecker.sol";
import { IPAsset } from "contracts/IPAsset.sol";
import { FranchiseRegistry } from "contracts/FranchiseRegistry.sol";

contract LinkIPAssetTypeCheckerHarness is LinkIPAssetTypeChecker {

    bool private _returnIsAssetRegistry;

    function setIsAssetRegistry(bool value) external {
        _returnIsAssetRegistry = value;
    }

    function _isAssetRegistry(address ipAssetRegistry) internal virtual override view returns(bool) {
        return _returnIsAssetRegistry;
    }

    function checkLinkEnd(address collection, uint256 id, uint256 assetTypeMask) view external returns (bool) {
        return _checkLinkEnd(collection, id, assetTypeMask);
    }

    function convertToMask(IPAsset[] calldata ipAssets, bool allowsExternal) pure external returns (uint256) {
        return _convertToMask(ipAssets, allowsExternal);
    }

    function supportsIPAssetType(uint256 mask, uint8 assetType) pure external returns (bool) {
        return _supportsIPAssetType(mask, assetType);
    }
}


contract LinkIPAssetTypeCheckerConvertToMaskTest is Test {

    LinkIPAssetTypeCheckerHarness public checker;

    error InvalidIPAssetArray();

    function setUp() public {
        checker = new LinkIPAssetTypeCheckerHarness();
    }

    function test_convertToMaskWithoutExternal() public {
        for (uint8 i = 1; i <= uint8(IPAsset.ITEM); i++) {
            IPAsset[] memory ipAssets = new IPAsset[](i);
            uint256 resultMask;
            for (uint8 j = 1; j <= i; j++) {
                ipAssets[j-1] = IPAsset(j);
                resultMask |= uint256(IPAsset(j));
            }
            uint256 mask = checker.convertToMask(ipAssets, false);
            assertEq(mask, resultMask);
        }
    }

    function test_convertToMaskWithExternal() public {
        for (uint8 i = 1; i <= uint8(IPAsset.ITEM); i++) {
            IPAsset[] memory ipAssets = new IPAsset[](i);
            uint256 resultMask;
            for (uint8 j = 1; j <= i; j++) {
                ipAssets[j-1] = IPAsset(j);
                resultMask |= uint256(IPAsset(j));
            }
            resultMask |= uint256(type(uint8).max);
            uint256 mask = checker.convertToMask(ipAssets, true);
            assertEq(mask, resultMask);
        }
    }

    function test_revert_convertToMaskWithExternal_ifEmptyArray() public {
        IPAsset[] memory ipAssets = new IPAsset[](0);
        vm.expectRevert(InvalidIPAssetArray.selector);
        checker.convertToMask(ipAssets, false);
    }

    function test_revert_convertToMaskWithExterna_ifZeroRow() public {
        IPAsset[] memory ipAssets = new IPAsset[](1);
        ipAssets[0] = IPAsset(0);
        vm.expectRevert(InvalidIPAssetArray.selector);
        checker.convertToMask(ipAssets, false);
    }
    
}

contract LinkIPAssetTypeCheckerSupportsAssetTypeTest is Test {

    LinkIPAssetTypeCheckerHarness public checker;

    error InvalidIPAssetArray();

    function setUp() public {
        checker = new LinkIPAssetTypeCheckerHarness();
    }

    function test_supportsIPAssetType_true() public {
        uint256 mask = 0;
        for (uint8 i = 1; i <= uint8(IPAsset.ITEM); i++) {
            mask |= uint256(IPAsset(i));
        }
        mask |= uint256(type(uint8).max);
        for (uint8 i = 1; i <= uint8(IPAsset.ITEM); i++) {
            assertTrue(checker.supportsIPAssetType(mask, i));
        }
        assertTrue(checker.supportsIPAssetType(mask, type(uint8).max));
    }

    function test_supportIPAssetType_false() public {
        uint256 zeroMask;
        for (uint8 i = 1; i <= uint8(IPAsset.ITEM); i++) {
            assertFalse(checker.supportsIPAssetType(zeroMask, i));
        }
        assertFalse(checker.supportsIPAssetType(zeroMask, type(uint8).max));
    }
    
}

contract LinkIPAssetTypeCheckerCheckLinkEndeTest is Test {

    LinkIPAssetTypeCheckerHarness public checker;

    error InvalidIPAssetArray();

    function setUp() public {
        checker = new LinkIPAssetTypeCheckerHarness();
    }


    
}