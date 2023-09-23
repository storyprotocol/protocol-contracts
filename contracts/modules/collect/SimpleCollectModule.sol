// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { UPGRADER_ROLE } from "contracts/access-control/ProtocolRoles.sol";
import { CollectModuleBase } from "contracts/modules/collect/CollectModuleBase.sol";

/// @title Simple Collect Module
/// @notice This simple collect module binds IP assets to mintable NFTs.
contract SimpleCollectModule is CollectModuleBase {

    /// @notice Initializes a mock collect module.
    /// @param franchiseRegistry The protocol-wide franchise registry address.
    /// @param defaultCollectNFTImpl The default collect NFT impl address.
    constructor(address franchiseRegistry, address defaultCollectNFTImpl) CollectModuleBase(franchiseRegistry, defaultCollectNFTImpl) {}

    /// @notice Initializes the collect module via UUPS proxying.
    /// @param accessControl The address utilized for contract access control.
    function initialize(address accessControl) public initializer {
        __UUPSUpgradeable_init();
        __AccessControlledUpgradeable_init(accessControl);
    }

    /// @dev Checks whether the collect action is authorized for an IP asset.
    function _isCollectAuthorized(uint256 franchiseId, uint256 ipAssetId) internal view override returns (bool) {
        address ipAssetRegistry = FRANCHISE_REGISTRY.ipAssetRegistryForId(franchiseId);
        return msg.sender == IERC721(ipAssetRegistry).ownerOf(ipAssetId);
    }

    /// @dev Additional authorization necessitated by UUPS module upgrades.
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

}
