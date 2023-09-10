// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import { CollectModuleBase } from "contracts/modules/collect/CollectModuleBase.sol";

// Mock constants to be used for identifying unauthorized franchises.
contract MockCollectModuleConstants {
    uint256 public constant UNAUTHORIZED_FRANCHISE_ID = 99;
}

/// @title Mock Collect Module
/// @notice This mock contract is used for testing the base collect module.
contract MockCollectModule is CollectModuleBase, MockCollectModuleConstants {

    // Whether the collect module is enabled for a specific IP asset.
    mapping(uint256 => mapping(uint256 => bool)) collectEnabled;

    /// @notice Initializes a mock collect module.
    /// @param franchiseRegistry The protocol-wide franchise registry address.
    /// @param defaultCollectNFTImpl The default collect NFT impl address.
    constructor(address franchiseRegistry, address defaultCollectNFTImpl) CollectModuleBase(franchiseRegistry, defaultCollectNFTImpl) {}

    /// @notice Initializes the collect module via UUPS proxying.
    /// @param accessControl The address utilized for contract access control.
    function initialize(address accessControl) public initializer {}

    /// @dev Checks whether the collect action is authorized for an IP asset.
    function _isCollectAuthorized(uint256 franchiseId, uint256) internal pure override returns (bool) {
        return franchiseId != UNAUTHORIZED_FRANCHISE_ID;
    }

    /// @dev Additional authorization necessitated by UUPS module upgrades.
    function _authorizeUpgrade(address newImplementation) internal override {}
}
