// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IRoyaltyDistributor } from "contracts/interfaces/modules/royalties/IRoyaltyDistributor.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { AccessControlledUpgradeable } from "contracts/access-control/AccessControlledUpgradeable.sol";
import { IIPAccountRegistry } from "contracts/interfaces/ip-accounts/IIPAccountRegistry.sol";
import { IRoyaltyPolicy } from "contracts/interfaces/modules/royalties/policies/IRoyaltyPolicy.sol";
import { RoyaltyNFT } from "contracts/modules/royalties/RoyaltyNFT.sol";
import { UPGRADER_ROLE, PROTOCOL_ADMIN_ROLE } from "contracts/access-control/ProtocolRoles.sol";

contract RoyaltyDistributor is Pausable, IRoyaltyDistributor, AccessControlledUpgradeable {

    IIPAccountRegistry public immutable ipAccountRegistry;
    RoyaltyNFT public immutable royaltyNFT;

    // ipAccount => royaltyPolicy
    mapping(address => address) private policies;

    constructor(address _ipAccountRegistry, address _royaltyNft) {
        ipAccountRegistry = IIPAccountRegistry(_ipAccountRegistry);
        royaltyNFT = RoyaltyNFT(_royaltyNft);
    }

    function setRoyaltyPolicy(
        address nftContract,
        uint256 tokenId,
        address royaltyPolicy,
        bytes calldata data
    ) external {
        address ipAccount = _ipAccount(nftContract, tokenId);
        policies[ipAccount] = royaltyPolicy;
        IRoyaltyPolicy(royaltyPolicy).initPolicy(ipAccount, data);
    }

    function getRoyaltyPolicy(
        address nftContract,
        uint256 tokenId
    ) external view returns (address) {
        address ipAccount = _ipAccount(nftContract, tokenId);
        return policies[ipAccount];
    }

    function updateDistribution(
        address nftContract,
        uint256 tokenId,
        bytes calldata data
    ) external {
        address ipAccount = ipAccountRegistry.createAccount(block.chainid, nftContract, tokenId, "");
        IRoyaltyPolicy(policies[ipAccount]).updateDistribution(ipAccount, data);
    }

    function distribute(address nftContract, uint256 tokenId, address token) external {
        address ipAccount = _ipAccount(nftContract, tokenId);
        IRoyaltyPolicy(policies[ipAccount]).distribute(ipAccount, token);
    }

    function claim(address account, address token) external {
        royaltyNFT.claim(account, token);
    }

    function pause() external onlyRole(PROTOCOL_ADMIN_ROLE) {
        _pause();
    }
    function unpause() external onlyRole(PROTOCOL_ADMIN_ROLE) {
        _unpause();
    }

    function _ipAccount(address nftContract, uint256 tokenId) internal view returns(address) {
        return ipAccountRegistry.account(block.chainid, nftContract, tokenId);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyRole(UPGRADER_ROLE) {}

}