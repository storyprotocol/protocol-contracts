// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { UPGRADER_ROLE } from "contracts/access-control/ProtocolRoles.sol";
import { CollectModuleBase } from "contracts/modules/collect/CollectModuleBase.sol";

/// @title Simple Collect Module
/// @notice This simple collect module binds IP assets to mintable NFTs.
contract SimpleCollectModule is CollectModuleBase {

    /// @notice Initializes a mock collect module.
    /// @param franchiseRegistry_ The protocol-wide franchise registry address.
    /// @param defaultCollectNftImpl_ The default collect NFT impl address.
    constructor(address franchiseRegistry_, address defaultCollectNftImpl_) CollectModuleBase(franchiseRegistry_, defaultCollectNftImpl_) {}

    /// @notice Initializes the collect module via UUPS proxying.
    /// @param accessControl_ The address utilized for contract access control.
    function initialize(address accessControl_) public initializer {
        __UUPSUpgradeable_init();
        __AccessControlledUpgradeable_init(accessControl_);
    }

    /// @dev Checks whether the collect action is authorized for an IP asset.
    function _isCollectAuthorized(uint256 franchiseId_, uint256 ipAssetId_) internal view override returns (bool) {
        address ipAssetRegistry = FRANCHISE_REGISTRY.ipAssetRegistryForId(franchiseId_);
        return msg.sender == IERC721(ipAssetRegistry).ownerOf(ipAssetId_);
    }

    /// @dev Additional authorization necessitated by UUPS module upgrades.
    function _authorizeUpgrade(address newImplementation_) internal override onlyRole(UPGRADER_ROLE) {}

}
