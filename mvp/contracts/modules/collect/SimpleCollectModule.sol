// SPDX-License-Identifier: UNLICENSED
// See Story Protocol Alpha Agreement: https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.18;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { CollectModuleBase } from "contracts/modules/collect/CollectModuleBase.sol";

/// @title Simple Collect Module
/// @notice This simple collect module links IP assets to mintable NFTs.
contract SimpleCollectModule is CollectModuleBase {

    /// @notice Initializes a mock collect module.
    /// @param franchise_ The protocol-wide franchise registry address.
    /// @param defaultCollectNftImpl_ The default collect NFT impl address.
    constructor(address franchise_, address defaultCollectNftImpl_) CollectModuleBase(franchise_, defaultCollectNftImpl_) {}

    /// @notice Initializes the collect module via UUPS proxying.
    /// @param accessControl_ The address utilized for contract access control.
    function initialize(address accessControl_) public initializer {
        __UUPSUpgradeable_init();
        __AccessControlledUpgradeable_init(accessControl_);
    }

    /// @dev Additional authorization necessitated by UUPS module upgrades.
    function _authorizeUpgrade(address newImplementation_) internal override onlyRole(AccessControl.UPGRADER_ROLE) {}

    /// @dev Checks whether the collect action is authorized for an IP asset.
    function _isCollectAuthorized(uint256 ipAssetId_) internal view override returns (bool) {
        address ipAssetOrg = REGISTRY.ipAssetOrg(ipAssetId_);
        return msg.sender == ipAssetOrg;
    }
}
