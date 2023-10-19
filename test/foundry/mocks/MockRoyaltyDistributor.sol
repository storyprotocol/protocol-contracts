// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import "contracts/modules/royalties/IRoyaltyDistributor.sol";
import { CollectModuleBase } from "contracts/modules/collect/CollectModuleBase.sol";

/// @title Mock Royalty Distributor
/// @notice This mock contract is used for testing the Royalty Terms Processor.
contract MockRoyaltyDistributor is IRoyaltyDistributor {
    address public defaultRoyaltyPolicy;
    /// @notice Set royalty policy to specified IP Asset.
    /// @param royaltyPolicy  The royalty distribution policy.
    function setRoyaltyPolicy(
        address,
        uint256,
        address royaltyPolicy,
        bytes calldata
    ) external {
        defaultRoyaltyPolicy = royaltyPolicy;
    }

    /// @notice Get royalty policy for specified IP Asset.
    /// @return  The address of royalty distribution policy.
    function getRoyaltyPolicy(address, uint256) external view returns (address) {
        return defaultRoyaltyPolicy;
    }

    /// @notice update royalty distribution plan for given IP Asset.
    /// @param nftContract address of NFT collection contract.
    /// @param tokenId The NFT token Id of NFT collection contract.
    /// @param data The royalty distribution plan data.
    function updateDistribution(address nftContract, uint256 tokenId, bytes calldata data) external {}

    /// @notice distribute royalty to each recipient according to royalty distribution plan for given IP Asset.
    /// @param nftContract address of NFT collection contract.
    /// @param tokenId The NFT token Id of NFT collection contract.
    /// @param token The ERC20 token for royalty.
    function distribute(address nftContract, uint256 tokenId, address token) external {}

    /// @notice claim royalty to account.
    /// @param account address of the account to which withdraw royalty which distributed before.
    function claim(address account, address token) external {}

    /// @notice pause the royalty distribution.
    function pause() external {}

    /// @notice unpause the royalty distribution.
    function unpause() external {}
}
