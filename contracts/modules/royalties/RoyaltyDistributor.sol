// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IRoyaltyDistributor } from "./IRoyaltyDistributor.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { IIPAccountRegistry } from "contracts/ip-accounts/IIPAccountRegistry.sol";
import { IRoyaltyPolicy } from "contracts/modules/royalties/policies/IRoyaltyPolicy.sol";
import { RoyaltyNFT } from "contracts/modules/royalties/RoyaltyNFT.sol";

contract RoyaltyDistributor is Pausable, IRoyaltyDistributor {

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
        address ipAccount = ipAccountRegistry.account(block.chainid, nftContract, tokenId);
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
        address ipAccount = _ipAccount(nftContract, tokenId);
        IRoyaltyPolicy(policies[ipAccount]).updateDistribution(ipAccount, data);
    }

    function distribute(address nftContract, uint256 tokenId, address token) external {
        address ipAccount = _ipAccount(nftContract, tokenId);
        IRoyaltyPolicy(policies[ipAccount]).distribute(ipAccount, token);
    }

    function claim(address account, address token) external {
        royaltyNFT.claim(account, token);
    }

    function pause() external {
        _pause();
    }
    function unpause() external {
        _unpause();
    }

    function _ipAccount(address nftContract, uint256 tokenId) internal view returns(address) {
        return ipAccountRegistry.account(block.chainid, nftContract, tokenId);
    }

}