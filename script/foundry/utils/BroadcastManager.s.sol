// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "script/foundry/utils/StringUtil.sol";

contract BroadcastManager is Script {

    address public admin = address(0x456);
    bool failIfDeployingToProd;

    function _beginBroadcast() internal {
        if (failIfDeployingToProd) {
            require(block.chainid != 1, "Cannot deploy to mainnet");
            // TODO: add other prod chains
        }
        uint256 deployerPrivateKey;
        if (block.chainid == 5) {
            deployerPrivateKey = vm.envUint("GOERLI_PRIVATEKEY");
            admin = vm.envAddress("GOERLI_ADMIN_ADDRESS");
            vm.startBroadcast(deployerPrivateKey);
        } else if (block.chainid == 11155111) {
            deployerPrivateKey = vm.envUint("SEPOLIA_PRIVATEKEY");
            admin = vm.envAddress("SEPOLIA_ADMIN_ADDRESS");
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
