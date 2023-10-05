// SPDX-License-Identifier: BUSL-1.1
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

    error NonExistIpAccountImpl();
    error IpAccountInitializationFailed();

    function createAccount(
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        bytes calldata initData
    ) external returns (address);

    function account(
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) external view returns (address);

    
    /// @notice Returns the IPAccount implementation address.
    /// @return address The IPAccount implementation address.
    function getIpAccountImpl() external view returns (address);
}
