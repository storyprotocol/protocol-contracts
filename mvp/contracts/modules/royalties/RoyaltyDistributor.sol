// SPDX-License-Identifier: UNLICENSED
// See Story Protocol Alpha Agreement: https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.19;

import { IRoyaltyDistributor } from "contracts/interfaces/modules/royalties/IRoyaltyDistributor.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { AccessControlledUpgradeable } from "contracts/access-control/AccessControlledUpgradeable.sol";
import { IIPAccountRegistry } from "contracts/interfaces/ip-accounts/IIPAccountRegistry.sol";
import { IRoyaltyPolicy } from "contracts/interfaces/modules/royalties/policies/IRoyaltyPolicy.sol";
import { RoyaltyNFT } from "contracts/modules/royalties/RoyaltyNFT.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";

contract RoyaltyDistributor is Pausable, IRoyaltyDistributor, AccessControlledUpgradeable {

    IIPAccountRegistry public immutable ipAccountRegistry;
    RoyaltyNFT public immutable royaltyNFT;

    // ipAccount => royaltyPolicy
    mapping(address => address) private policies;

    constructor(address ipAccountRegistry_, address royaltyNft_) {
        ipAccountRegistry = IIPAccountRegistry(ipAccountRegistry_);
        royaltyNFT = RoyaltyNFT(royaltyNft_);
    }

    function setRoyaltyPolicy(
        address nftContract_,
        uint256 tokenId_,
        address royaltyPolicy_,
        bytes calldata data_
    ) external {
        address ipAccount = _ipAccount(nftContract_, tokenId_);
        policies[ipAccount] = royaltyPolicy_;
        IRoyaltyPolicy(royaltyPolicy_).initPolicy(ipAccount, data_);
    }

    function updateDistribution(
        address nftContract_,
        uint256 tokenId_,
        bytes calldata data_
    ) external {
        address ipAccount = ipAccountRegistry.createAccount(block.chainid, nftContract_, tokenId_, "");
        IRoyaltyPolicy(policies[ipAccount]).updateDistribution(ipAccount, data_);
    }

    function distribute(address nftContract_, uint256 tokenId_, address token_) external {
        address ipAccount = _ipAccount(nftContract_, tokenId_);
        IRoyaltyPolicy(policies[ipAccount]).distribute(ipAccount, token_);
    }

    function claim(address account_, address token_) external {
        royaltyNFT.claim(account_, token_);
    }

    function pause() external onlyRole(AccessControl.PROTOCOL_ADMIN_ROLE) {
        _pause();
    }
    function unpause() external onlyRole(AccessControl.PROTOCOL_ADMIN_ROLE) {
        _unpause();
    }

    function getRoyaltyPolicy(
        address nftContract_,
        uint256 tokenId_
    ) external view returns (address) {
        address ipAccount = _ipAccount(nftContract_, tokenId_);
        return policies[ipAccount];
    }

    function _authorizeUpgrade(
        address newImplementation_
    ) internal virtual override onlyRole(AccessControl.UPGRADER_ROLE) {}

    function _ipAccount(address nftContract_, uint256 tokenId_) internal view returns(address) {
        return ipAccountRegistry.account(block.chainid, nftContract_, tokenId_);
    }
}
