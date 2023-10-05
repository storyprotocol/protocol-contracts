// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import { CollectPaymentModuleBase } from "contracts/modules/collect/CollectPaymentModuleBase.sol";

/// @title Mock Payment Collect Module
/// @notice Mock contract used for testing the base payment collect module.
contract MockCollectPaymentModule is CollectPaymentModuleBase {

    // Whether the collect module is enabled for a specific IP asset.
    mapping(uint256 => mapping(uint256 => bool)) collectEnabled;

    /// @notice Initializes a mock collect payment module.
    /// @param franchiseRegistry The protocol-wide franchise registry address.
    /// @param defaultCollectNftImpl The default collect NFT impl address.
    constructor(address franchiseRegistry, address defaultCollectNftImpl) CollectPaymentModuleBase(franchiseRegistry, defaultCollectNftImpl) {}

    /// @notice Initializes the collect module via UUPS proxying.
    /// @param accessControl The address utilized for contract access control.
    function initialize(address accessControl) public initializer {}

    /// @dev Checks whether the collect action is authorized for an IP asset.
    function _isCollectAuthorized(uint256, uint256) internal pure override returns (bool) {
        return true;
    }

    /// @dev Additional authorization necessitated by UUPS module upgrades.
    function _authorizeUpgrade(address newImplementation) internal override {}
}
