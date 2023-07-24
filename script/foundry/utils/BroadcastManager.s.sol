// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "script/foundry/utils/StringUtil.sol";

contract BroadcastManager is Script {

    address public deployer = address(0x123);
    address public admin = address(0x456);

    function _beginBroadcast() internal {
        uint256 deployerPrivateKey;
        if (block.chainid == 5) {
            deployerPrivateKey = vm.envUint("GOERLI_PRIVATEKEY");
            admin = vm.envAddress("GOERLI_ADMIN_ADDRESS");
            vm.startBroadcast(deployerPrivateKey);
        } else {
            vm.startPrank(deployer);
        }
    }

    function _endBroadcast() internal {
        if (block.chainid == 5) {
            vm.stopBroadcast();
        } else {
            vm.stopPrank();
        }
    }
}
