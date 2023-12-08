// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import { Errors } from "contracts/lib/Errors.sol";
import "contracts/ip-accounts/IPAccountRegistry.sol";
import "mvp/test/foundry/mocks/MockIPAccount.sol";

contract RegistryTest is Test {
    IPAccountRegistry public registry;
    MockIPAccount public implementation;
    uint256 chainId;
    address tokenAddress;
    uint256 tokenId;

    error IpAccountInitializationFailed();

    function setUp() public {
        implementation = new MockIPAccount();
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
        vm.expectRevert(Errors.IPAccountRegistry_InitializationFailed.selector);
        registry.createAccount(
            chainId,
            tokenAddress,
            tokenId,
            abi.encodeWithSignature("foo(bool)", false)
        );
    }
}
