// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "mvp/test/foundry/RoyaltyDistributor.t.sol";

contract RoyaltyDistributorForkTest is RoyaltyDistributorTest {
    function _getSplitMain() internal virtual override returns(ISplitMain) {
        string memory mainnetRpc;
        console.log("fork mainnet");
        try vm.envString("MAINNET_RPC_URL") returns (string memory rpcUrl) {
            mainnetRpc = rpcUrl;
            console.log("Using mainnet RPC in environment variable");
        } catch {
            fail("Missing environment variable 'MAINNET_RPC_URL'");
        }
        uint256 mainnetFork = vm.createFork(mainnetRpc);
        vm.selectFork(mainnetFork);
        assertEq(vm.activeFork(), mainnetFork);
        return ISplitMain(0x2ed6c4B5dA6378c7897AC67Ba9e43102Feb694EE);
    }
}
