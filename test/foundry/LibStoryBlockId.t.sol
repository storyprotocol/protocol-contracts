// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "contracts/ip-assets/LibIPAssetID.sol";
import "contracts/IPAsset.sol";

contract FranchiseRegistryTest is Test {

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
        assertEq(LibIPAssetID._zeroId(IPAsset.STORY), _ZERO_ID_STORY);
        assertEq(LibIPAssetID._zeroId(IPAsset.CHARACTER), _ZERO_ID_CHARACTER);
        assertEq(LibIPAssetID._zeroId(IPAsset.ART), _ZERO_ID_ART);
        assertEq(LibIPAssetID._zeroId(IPAsset.GROUP), _ZERO_ID_GROUP);
        assertEq(LibIPAssetID._zeroId(IPAsset.LOCATION), _ZERO_ID_LOCATION);
        assertEq(LibIPAssetID._zeroId(IPAsset.ITEM), _ZERO_ID_ITEM);
    }

    function test_lastIds() public {
        assertEq(LibIPAssetID._lastId(IPAsset.STORY), _ZERO_ID_CHARACTER - 1);
        assertEq(LibIPAssetID._lastId(IPAsset.CHARACTER), _ZERO_ID_ART - 1);
        assertEq(LibIPAssetID._lastId(IPAsset.ART), _ZERO_ID_GROUP - 1);
        assertEq(LibIPAssetID._lastId(IPAsset.GROUP), _ZERO_ID_LOCATION - 1);
        assertEq(LibIPAssetID._lastId(IPAsset.LOCATION), _ZERO_ID_ITEM - 1);
        assertEq(LibIPAssetID._lastId(IPAsset.ITEM), _LAST_ID_ITEM);
    }

    function test_IPAssetTypes() public {
        assertEq(uint8(LibIPAssetID._ipAssetTypeFor(_ZERO_ID_STORY)), uint8(IPAsset.UNDEFINED));

        assertEq(uint8(LibIPAssetID._ipAssetTypeFor(_ZERO_ID_STORY + 1)), uint8(IPAsset.STORY));
        assertEq(uint8(LibIPAssetID._ipAssetTypeFor(_ZERO_ID_STORY + _HALF_ID_RANGE)), uint8(IPAsset.STORY));
        assertEq(uint8(LibIPAssetID._ipAssetTypeFor(_ZERO_ID_CHARACTER - 1)), uint8(IPAsset.STORY));
        
        assertEq(uint8(LibIPAssetID._ipAssetTypeFor(_ZERO_ID_CHARACTER)), uint8(IPAsset.UNDEFINED));
        assertEq(uint8(LibIPAssetID._ipAssetTypeFor(_ZERO_ID_CHARACTER + 1)), uint8(IPAsset.CHARACTER));
        assertEq(uint8(LibIPAssetID._ipAssetTypeFor(_ZERO_ID_CHARACTER + _HALF_ID_RANGE)), uint8(IPAsset.CHARACTER));
        assertEq(uint8(LibIPAssetID._ipAssetTypeFor(_ZERO_ID_ART - 1)), uint8(IPAsset.CHARACTER));

        assertEq(uint8(LibIPAssetID._ipAssetTypeFor(_ZERO_ID_ART)), uint8(IPAsset.UNDEFINED));
        assertEq(uint8(LibIPAssetID._ipAssetTypeFor(_ZERO_ID_ART + 1)), uint8(IPAsset.ART));
        assertEq(uint8(LibIPAssetID._ipAssetTypeFor(_ZERO_ID_ART + _HALF_ID_RANGE)), uint8(IPAsset.ART));
        assertEq(uint8(LibIPAssetID._ipAssetTypeFor(_ZERO_ID_GROUP - 1)), uint8(IPAsset.ART));

        assertEq(uint8(LibIPAssetID._ipAssetTypeFor(_ZERO_ID_GROUP)), uint8(IPAsset.UNDEFINED));
        assertEq(uint8(LibIPAssetID._ipAssetTypeFor(_ZERO_ID_GROUP + 1)), uint8(IPAsset.GROUP));
        assertEq(uint8(LibIPAssetID._ipAssetTypeFor(_ZERO_ID_GROUP + _HALF_ID_RANGE)), uint8(IPAsset.GROUP));
        assertEq(uint8(LibIPAssetID._ipAssetTypeFor(_ZERO_ID_LOCATION - 1)), uint8(IPAsset.GROUP));

        assertEq(uint8(LibIPAssetID._ipAssetTypeFor(_ZERO_ID_LOCATION)), uint8(IPAsset.UNDEFINED));
        assertEq(uint8(LibIPAssetID._ipAssetTypeFor(_ZERO_ID_LOCATION + 1)), uint8(IPAsset.LOCATION));
        assertEq(uint8(LibIPAssetID._ipAssetTypeFor(_ZERO_ID_LOCATION + _HALF_ID_RANGE)), uint8(IPAsset.LOCATION));
        assertEq(uint8(LibIPAssetID._ipAssetTypeFor(_ZERO_ID_ITEM - 1)), uint8(IPAsset.LOCATION));

        assertEq(uint8(LibIPAssetID._ipAssetTypeFor(_ZERO_ID_ITEM)), uint8(IPAsset.UNDEFINED));
        assertEq(uint8(LibIPAssetID._ipAssetTypeFor(_ZERO_ID_ITEM + 1)), uint8(IPAsset.ITEM));
        assertEq(uint8(LibIPAssetID._ipAssetTypeFor(_ZERO_ID_ITEM + _HALF_ID_RANGE)), uint8(IPAsset.ITEM));
        assertEq(uint8(LibIPAssetID._ipAssetTypeFor(_LAST_ID_ITEM)), uint8(IPAsset.ITEM));

        assertEq(uint8(LibIPAssetID._ipAssetTypeFor(_LAST_ID_ITEM + 1)), uint8(IPAsset.UNDEFINED));
    }
}
