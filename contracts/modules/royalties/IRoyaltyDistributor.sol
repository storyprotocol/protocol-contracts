// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

interface IRoyaltyDistributor {

    event DistributeRoyalties(
        address indexed sourceAccount,
        address indexed token,
        uint256 amount,
        address indexed distributorAddress
    );

    event ClaimRoyalties(
        address indexed account,
        address indexed token,
        uint256 amount
    );

    event SetRoyaltyPolicy(
        address indexed account,
        address indexed royaltyPolicy
    );

    event UpdateDistribution(address indexed account);

    function setRoyaltyPolicy(address nftContract, uint256 tokenId, address royaltyPolicy, bytes calldata data) external;
    function getRoyaltyPolicy(address nftContract, uint256 tokenId) external view returns (address);
    function updateDistribution(address nftContract, uint256 tokenId, bytes calldata data) external;
    function distribute(address nftContract, uint256 tokenId, address token) external;
    function claim(address account, address token) external;
    function pause() external;
    function unpause() external;
}