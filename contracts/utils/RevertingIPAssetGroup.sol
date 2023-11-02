// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.13;

/// @title RevertingIPOrg
/// @author Raul Martinez
/// @notice Only used to initialize the beacon in IPOrgFactor,
/// breaking a circular dependency on creation and keeping the beacon immutable
contract RevertingIPOrg {
    error DontUseThisContract();

    function initialize() external pure {
        revert DontUseThisContract();
    }
}
