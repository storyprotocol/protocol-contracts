// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "test/foundry/utils/ProxyHelper.sol";
import "script/foundry/utils/StringUtil.sol";
import "contracts/story-blocks/StoryBlocksRegistryFactory.sol";
import "contracts/FranchiseRegistry.sol";
import "contracts/access-control/AccessControlSingleton.sol";

contract Deploy is Script, ProxyHelper {

    using StringUtil for uint256;
    using stdJson for string;

    StoryBlocksRegistryFactory public factory;
    FranchiseRegistry public registry;
    AccessControlSingleton public access;

    address public deployer = address(0x123);

    /// @dev To use, run the following command (e.g. for Goerli):
    /// forge script script/Deploy.s.sol:Deploy --rpc-url $GOERLI_RPC_URL --broadcast --verify -vvvv
    function run() public {
        uint256 deployerPrivateKey;
        if (block.chainid == 5) {
            deployerPrivateKey = vm.envUint("GOERLI_PRIVATEKEY");
            vm.startBroadcast(deployerPrivateKey);
        } else {
            vm.startPrank(deployer);
        }
        
        string memory chainId = (block.chainid).toString();
        string memory contractGroup;

        /// DEPLOY STORY BLOCKS REGISTRY FACTORY
        console.log("Deploying Story Blocks Registry Factory...");
        factory = new StoryBlocksRegistryFactory();
        string memory contractOutput = vm.serializeAddress(contractGroup, "storyBlocksRegistryFactory", address(factory));
        console.log("Story blocks registry factory deployed to:", address(factory));

        /// DEPLOY ACCESS CONTROL SINGLETON
        console.log("Deploying Access Control Singleton...");
        access = new AccessControlSingleton();
        address accessControl = address(access);
        contractOutput = vm.serializeAddress(contractGroup, "accessControlSingleton", accessControl);
        console.log("Access control singleton deployed to:", accessControl);

        /// DEPLOY FRANCHISE REGISTRY
        console.log("Deploying Franchise Registry Impl...");
        FranchiseRegistry impl = new FranchiseRegistry(address(factory));
        contractOutput = vm.serializeAddress(contractGroup, "franchiseRegistry-impl", address(impl));
        console.log("Franchise registry implementation deployed to:", address(impl));

        console.log("Deploying Franchise Registry Proxy...");
        registry = FranchiseRegistry(
            _deployUUPSProxy(
                address(impl),
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize(address)"))), accessControl
                )
            )
        );
        contractOutput = vm.serializeAddress(contractGroup, "franchiseRegistry-proxy", address(registry));
        console.log("Franchise registry proxy deployed to:", address(registry));

        string memory finalJson = chainId.serialize(chainId, contractOutput);
        
        if (block.chainid == 5) {
            vm.writeJson(finalJson, "./deployment-public.json");
            vm.stopBroadcast();
        } else {
            vm.writeJson(finalJson, "./deployment-local.json");
            vm.stopPrank();
        }
    }

}
