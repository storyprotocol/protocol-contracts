// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title Royalty Module Interface
/// @notice The Royalty module distribute royalty/revenue across IP graph.
///         It supports customized royalty distributing policies for each individual IP Asset.
interface IRoyaltyDistributor {

    /// @dev Emitted when distribute royalty token.
    ///
    /// @param sourceAccount The address of account from which distribute royalty to other recipients.
    /// @param token The ERC20 royalty token.
    /// @param amount The amount of ERC20 royalty token are distributed.
    event DistributeRoyalties(
        address indexed sourceAccount,
        address indexed token,
        uint256 amount
    );

    /// @dev Emitted after withdraw royalty to payee's account.
    ///
    /// @param account The address of account to which withdraw royalty.
    /// @param token The ERC20 royalty token.
    /// @param amount The amount of ERC20 royalty token are claimed.
    event ClaimRoyalties(
        address indexed account,
        address indexed token,
        uint256 amount
    );

    /// @dev Emitted after set RoyaltyPolicy to specified IP Account.
    ///
    /// @param account The IP Account to which set royalty policy.
    /// @param royaltyPolicy the address of royalty policy implements IRoyaltyPolicy interface.
    event SetRoyaltyPolicy(
        address indexed account,
        address indexed royaltyPolicy
    );

    /// @dev Emitted after updated the royalty distribution plan.
    ///
    /// @param account The IP Account from which distribute the royalty.
    event UpdateDistribution(address indexed account);

    /// @notice Set royalty policy to specified IP Asset.
    /// @param nftContract_ address of NFT collection contract.
    /// @param tokenId_ The NFT token Id of NFT collection contract.
    /// @param royaltyPolicy_  The royalty distribution policy.
    /// @param data_ The initial data of the royalty distribution policy.
    function setRoyaltyPolicy(address nftContract_, uint256 tokenId_, address royaltyPolicy_, bytes calldata data_) external;

    /// @notice update royalty distribution plan for given IP Asset.
    /// @param nftContract_ address of NFT collection contract.
    /// @param tokenId_ The NFT token Id of NFT collection contract.
    /// @param data_ The royalty distribution plan data.
    function updateDistribution(address nftContract_, uint256 tokenId_, bytes calldata data_) external;

    /// @notice distribute royalty to each recipient according to royalty distribution plan for given IP Asset.
    /// @param nftContract_ address of NFT collection contract.
    /// @param tokenId_ The NFT token Id of NFT collection contract.
    /// @param token_ The ERC20 token for royalty.
    function distribute(address nftContract_, uint256 tokenId_, address token_) external;

    /// @notice claim royalty to account.
    /// @param account_ address of the account to which withdraw royalty which distributed before.
    function claim(address account_, address token_) external;

    /// @notice pause the royalty distribution.
    function pause() external;

    /// @notice unpause the royalty distribution.
    function unpause() external;

    /// @notice Get royalty policy for specified IP Asset.
    /// @param nftContract_ address of NFT collection contract.
    /// @param tokenId_ The NFT token Id of NFT collection contract.
    /// @return  The address of royalty distribution policy.
    function getRoyaltyPolicy(address nftContract_, uint256 tokenId_) external view returns (address);
}
