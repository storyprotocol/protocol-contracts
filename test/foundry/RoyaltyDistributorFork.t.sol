// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "test/foundry/RoyaltyDistributor.t.sol";

contract RoyaltyDistributorForkTest is RoyaltyDistributorTest {
    function _getSplitMain() internal virtual override returns(ISplitMain) {
        uint256 mainnetFork = vm.createFork(vm.envString("MAINNET_RPC_URL"), 18117657);
        vm.selectFork(mainnetFork);
        assertEq(vm.activeFork(), mainnetFork);
        console.log(block.number);
        return ISplitMain(0x2ed6c4B5dA6378c7897AC67Ba9e43102Feb694EE);
    }
}
