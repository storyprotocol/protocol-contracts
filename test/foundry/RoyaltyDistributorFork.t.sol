// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "test/foundry/RoyaltyDistributor.t.sol";

contract RoyaltyDistributorForkTest is RoyaltyDistributorTest {
    function _getSplitMain() internal virtual override returns(ISplitMain) {
        string memory mainnetRpc;
        try vm.envString("MAINNET_RPC_URL") returns (string memory rpcUrl) {
            mainnetRpc = rpcUrl;
        } catch {
            mainnetRpc = "https://rpc.ankr.com/eth";
        }
        console.log(mainnetRpc);
        uint256 mainnetFork = vm.createFork(mainnetRpc);
        vm.selectFork(mainnetFork);
        assertEq(vm.activeFork(), mainnetFork);
        console.log(block.number);
        return ISplitMain(0x2ed6c4B5dA6378c7897AC67Ba9e43102Feb694EE);
    }
}
