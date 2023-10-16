// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.13;

/// @title RevertingIPAssetGroup
/// @author Raul Martinez
/// @notice Only used to initialize the beacon in IPAssetGroupFactor,
/// breaking a circular dependency on creation and keeping the beacon immutable
contract RevertingIPAssetGroup {
    error DontUseThisContract();

    function initialize() external pure {
        revert DontUseThisContract();
    }
}
