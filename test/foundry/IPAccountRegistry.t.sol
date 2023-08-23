// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "contracts/ip-accounts/IPAccountRegistry.sol";
import "test/foundry/mocks/MockIpAccount.sol";

contract RegistryTest is Test {
    IPAccountRegistry public registry;
    MockIpAccount public implementation;
    uint256 chainId;
    address tokenAddress;
    uint256 tokenId;

    error IpAccountInitializationFailed();

    function setUp() public {
        implementation = new MockIpAccount();
        registry = new IPAccountRegistry(address(implementation));
        chainId = 100;
        tokenAddress = address(200);
        tokenId = 300;
    }

    function test_createAccount() public {
        address ipAccountAddr;
        ipAccountAddr = registry.createAccount(
            chainId,
            tokenAddress,
            tokenId,
            abi.encodeWithSignature("foo(bool)", true)
        );

        address registryComputedAddress = registry.account(
            chainId,
            tokenAddress,
            tokenId
        );
        assertEq(ipAccountAddr, registryComputedAddress);

        IPAccountImpl ipAccount = IPAccountImpl(payable(ipAccountAddr));

        (uint256 chainId_, address tokenAddress_, uint256 tokenId_) = ipAccount.token();
        assertEq(chainId_, chainId);
        assertEq(tokenAddress_, tokenAddress);
        assertEq(tokenId_, tokenId);
    }

    function test_revert_createAccount_ifInitFailed() public {
        vm.expectRevert(IpAccountInitializationFailed.selector);
        registry.createAccount(
            chainId,
            tokenAddress,
            tokenId,
            abi.encodeWithSignature("foo(bool)", false)
        );
    }
}
