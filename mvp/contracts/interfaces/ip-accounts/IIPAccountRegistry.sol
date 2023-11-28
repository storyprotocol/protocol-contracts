// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IIPAccountRegistry {

    event AccountCreated(
        address account,
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        uint256 salt
    );

    function createAccount(
        uint256 chainId_,
        address tokenContract_,
        uint256 tokenId_,
        bytes calldata initData
    ) external returns (address);

    function account(
        uint256 chainId_,
        address tokenContract_,
        uint256 tokenId_
    ) external view returns (address);

    
    /// @notice Returns the IPAccount implementation address.
    /// @return address The IPAccount implementation address.
    function getIpAccountImpl() external view returns (address);
}
