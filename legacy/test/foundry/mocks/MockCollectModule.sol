// SPDX-License-Identifier: UNLICENSED
// See Story Protocol Alpha Agreement: https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.18;

import { CollectModuleBase } from "mvp/contracts/modules/collect/CollectModuleBase.sol";

/// @title Mock Collect Module
/// @notice This mock contract is used for testing the base collect module.
contract MockCollectModule is CollectModuleBase {
    // Whether the collect module is enabled for a specific IP asset.
    mapping(uint256 => mapping(uint256 => bool)) collectEnabled;

    /// @notice Initializes a mock collect module.
    /// @param registry_ The protocol-wide franchise registry address.
    /// @param defaultCollectNftImpl_ The default collect NFT impl address.
    constructor(
        address registry_,
        address defaultCollectNftImpl_
    ) CollectModuleBase(registry_, defaultCollectNftImpl_) {}

    /// @notice Initializes the collect module via UUPS proxying.
    /// @param accessControl_ The address utilized for contract access control.
    function initialize(address accessControl_) public initializer {}

    /// @dev Checks whether the collect action is authorized for an IP asset.
    function _isCollectAuthorized(
        uint256
    ) internal pure virtual override returns (bool) {
        return true;
    }

    /// @dev Additional authorization necessitated by UUPS module upgrades.
    function _authorizeUpgrade(address newImplementation) internal override {}
}
