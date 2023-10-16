// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "contracts/lib/IPAsset.sol";
import "contracts/lib/IPAsset.sol";

contract IPAssetControllerTest is Test {

    uint256 private constant _ID_RANGE = 10**12;
    uint256 private constant _HALF_ID_RANGE = 5**12;
    uint256 private constant _ZERO_ID_STORY = 0;
    uint256 private constant _ZERO_ID_CHARACTER = _ID_RANGE + _ZERO_ID_STORY;
    uint256 private constant _ZERO_ID_ART = _ID_RANGE + _ZERO_ID_CHARACTER;
    uint256 private constant _ZERO_ID_GROUP = _ID_RANGE + _ZERO_ID_ART;
    uint256 private constant _ZERO_ID_LOCATION = _ID_RANGE + _ZERO_ID_GROUP;
    uint256 private constant _ZERO_ID_ITEM = _ID_RANGE + _ZERO_ID_LOCATION;
    uint256 private constant _LAST_ID_ITEM = _ID_RANGE + _ZERO_ID_ITEM - 1;


    function test_zeroIds() public {
        assertEq(IPAsset._zeroId(IPAsset.IPAssetType.STORY), _ZERO_ID_STORY);
        assertEq(IPAsset._zeroId(IPAsset.IPAssetType.CHARACTER), _ZERO_ID_CHARACTER);
        assertEq(IPAsset._zeroId(IPAsset.IPAssetType.ART), _ZERO_ID_ART);
        assertEq(IPAsset._zeroId(IPAsset.IPAssetType.GROUP), _ZERO_ID_GROUP);
        assertEq(IPAsset._zeroId(IPAsset.IPAssetType.LOCATION), _ZERO_ID_LOCATION);
        assertEq(IPAsset._zeroId(IPAsset.IPAssetType.ITEM), _ZERO_ID_ITEM);
    }

    function test_lastIds() public {
        assertEq(IPAsset._lastId(IPAsset.IPAssetType.STORY), _ZERO_ID_CHARACTER - 1);
        assertEq(IPAsset._lastId(IPAsset.IPAssetType.CHARACTER), _ZERO_ID_ART - 1);
        assertEq(IPAsset._lastId(IPAsset.IPAssetType.ART), _ZERO_ID_GROUP - 1);
        assertEq(IPAsset._lastId(IPAsset.IPAssetType.GROUP), _ZERO_ID_LOCATION - 1);
        assertEq(IPAsset._lastId(IPAsset.IPAssetType.LOCATION), _ZERO_ID_ITEM - 1);
        assertEq(IPAsset._lastId(IPAsset.IPAssetType.ITEM), _LAST_ID_ITEM);
    }

    function test_IPAssetTypes() public {
        assertEq(uint8(IPAsset._ipAssetTypeFor(_ZERO_ID_STORY)), uint8(IPAsset.IPAssetType.UNDEFINED));

        assertEq(uint8(IPAsset._ipAssetTypeFor(_ZERO_ID_STORY + 1)), uint8(IPAsset.IPAssetType.STORY));
        assertEq(uint8(IPAsset._ipAssetTypeFor(_ZERO_ID_STORY + _HALF_ID_RANGE)), uint8(IPAsset.IPAssetType.STORY));
        assertEq(uint8(IPAsset._ipAssetTypeFor(_ZERO_ID_CHARACTER - 1)), uint8(IPAsset.IPAssetType.STORY));
        
        assertEq(uint8(IPAsset._ipAssetTypeFor(_ZERO_ID_CHARACTER)), uint8(IPAsset.IPAssetType.UNDEFINED));
        assertEq(uint8(IPAsset._ipAssetTypeFor(_ZERO_ID_CHARACTER + 1)), uint8(IPAsset.IPAssetType.CHARACTER));
        assertEq(uint8(IPAsset._ipAssetTypeFor(_ZERO_ID_CHARACTER + _HALF_ID_RANGE)), uint8(IPAsset.IPAssetType.CHARACTER));
        assertEq(uint8(IPAsset._ipAssetTypeFor(_ZERO_ID_ART - 1)), uint8(IPAsset.IPAssetType.CHARACTER));

        assertEq(uint8(IPAsset._ipAssetTypeFor(_ZERO_ID_ART)), uint8(IPAsset.IPAssetType.UNDEFINED));
        assertEq(uint8(IPAsset._ipAssetTypeFor(_ZERO_ID_ART + 1)), uint8(IPAsset.IPAssetType.ART));
        assertEq(uint8(IPAsset._ipAssetTypeFor(_ZERO_ID_ART + _HALF_ID_RANGE)), uint8(IPAsset.IPAssetType.ART));
        assertEq(uint8(IPAsset._ipAssetTypeFor(_ZERO_ID_GROUP - 1)), uint8(IPAsset.IPAssetType.ART));

        assertEq(uint8(IPAsset._ipAssetTypeFor(_ZERO_ID_GROUP)), uint8(IPAsset.IPAssetType.UNDEFINED));
        assertEq(uint8(IPAsset._ipAssetTypeFor(_ZERO_ID_GROUP + 1)), uint8(IPAsset.IPAssetType.GROUP));
        assertEq(uint8(IPAsset._ipAssetTypeFor(_ZERO_ID_GROUP + _HALF_ID_RANGE)), uint8(IPAsset.IPAssetType.GROUP));
        assertEq(uint8(IPAsset._ipAssetTypeFor(_ZERO_ID_LOCATION - 1)), uint8(IPAsset.IPAssetType.GROUP));

        assertEq(uint8(IPAsset._ipAssetTypeFor(_ZERO_ID_LOCATION)), uint8(IPAsset.IPAssetType.UNDEFINED));
        assertEq(uint8(IPAsset._ipAssetTypeFor(_ZERO_ID_LOCATION + 1)), uint8(IPAsset.IPAssetType.LOCATION));
        assertEq(uint8(IPAsset._ipAssetTypeFor(_ZERO_ID_LOCATION + _HALF_ID_RANGE)), uint8(IPAsset.IPAssetType.LOCATION));
        assertEq(uint8(IPAsset._ipAssetTypeFor(_ZERO_ID_ITEM - 1)), uint8(IPAsset.IPAssetType.LOCATION));

        assertEq(uint8(IPAsset._ipAssetTypeFor(_ZERO_ID_ITEM)), uint8(IPAsset.IPAssetType.UNDEFINED));
        assertEq(uint8(IPAsset._ipAssetTypeFor(_ZERO_ID_ITEM + 1)), uint8(IPAsset.IPAssetType.ITEM));
        assertEq(uint8(IPAsset._ipAssetTypeFor(_ZERO_ID_ITEM + _HALF_ID_RANGE)), uint8(IPAsset.IPAssetType.ITEM));
        assertEq(uint8(IPAsset._ipAssetTypeFor(_LAST_ID_ITEM)), uint8(IPAsset.IPAssetType.ITEM));

        assertEq(uint8(IPAsset._ipAssetTypeFor(_LAST_ID_ITEM + 1)), uint8(IPAsset.IPAssetType.UNDEFINED));
    }
}
