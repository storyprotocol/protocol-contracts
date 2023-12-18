// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "script/foundry/utils/StringUtil.sol";

contract BroadcastManager is Script {

    address public multisig;
    address public deployer;

    function _beginBroadcast() internal {
        uint256 deployerPrivateKey;
        if (block.chainid == 11155111) {
            deployerPrivateKey = vm.envUint("SEPOLIA_PRIVATEKEY");
            deployer = vm.envAddress("SEPOLIA_DEPLOYER_ADDRESS");
            multisig = vm.envAddress("SEPOLIA_MULTISIG_ADDRESS");
            vm.startBroadcast(deployerPrivateKey);

        } else if (block.chainid == 31337) {
            multisig = address(0x456);
            deployer = address(0x999);
            vm.startPrank(deployer);
        } else {
            revert("Unsupported chain");
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
