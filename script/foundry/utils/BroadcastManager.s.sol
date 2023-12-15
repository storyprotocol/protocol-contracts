// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "script/foundry/utils/StringUtil.sol";

contract BroadcastManager is Script {

    address public admin = address(0x456);
    bool public configureInScript = true;
    bool public deployHooks = true;

    function _beginBroadcast() internal {
        uint256 deployerPrivateKey;
        configureInScript = vm.envBool("CONFIGURE_IN_SCRIPT");
        deployHooks = vm.envBool("DEPLOY_HOOKS");
        if (block.chainid == 11155111) {
            deployerPrivateKey = vm.envUint("SEPOLIA_PRIVATEKEY");
            admin = vm.envAddress("SEPOLIA_MULTISIG_ADDRESS");
            vm.startBroadcast(deployerPrivateKey);
        } else {
            vm.startPrank(admin);
        }
    }

    function _endBroadcast() internal {
        if (block.chainid == 31337) {
            vm.stopPrank();
        } else {
            vm.stopBroadcast();
        }
    }
}
