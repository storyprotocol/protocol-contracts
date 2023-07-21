// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
/*
import "forge-std/Script.sol";
import "test/foundry/utils/ProxyHelper.sol";
import "script/foundry/utils/StringUtil.sol";
import "script/foundry/utils/JsonDeploymentHandler.sol";


contract DeployRelationshipProcessors is Script, JsonDeploymentHandler, ProxyHelper {

    using StringUtil for uint256;
    using stdJson for string;

    address public deployer = address(0x123);
    address public admin = address(0x456);

    address ipAssetsFactory;
    address accessControl;
    address franchiseRegistry;

    constructor() JsonDeploymentHandler("") {
    }

    /// @dev To use, run the following command (e.g. for Goerli):
    /// forge script script/Deploy.s.sol:Deploy --rpc-url $GOERLI_RPC_URL --broadcast --verify -vvvv
    function run() public {
        uint256 deployerPrivateKey;
        if (block.chainid == 5) {
            deployerPrivateKey = vm.envUint("GOERLI_PRIVATEKEY");
            admin = vm.envAddress("GOERLI_ADMIN_ADDRESS");
            vm.startBroadcast(deployerPrivateKey);
        } else {
            vm.startPrank(deployer);
        }
        _readDeployment();
        string memory contractKey;
        address previousAddress;
        address newAddress;
        
        /// IP ASSETS REGISTRY FACTORY
        contractKey = "IPAssetRegistryFactory";
        previousAddress = _readAddress(contractKey);        
        if (previousAddress != address(0)) {
            console.log(string.concat(contractKey," already deployed to:"), previousAddress);
        } else {
            console.log(string.concat("Deploying ", contractKey, "..."));
            newAddress = address(new IPAssetRegistryFactory());
            _writeAddress(contractKey, newAddress);
            console.log(string.concat(contractKey, " deployed to:"), newAddress);
        }
        ipAssetsFactory = newAddress;

        /// ACCESS CONTROL SINGLETON
        contractKey = "AccessControlSingleton-Impl";
        previousAddress = _readAddress(contractKey);        
        if (previousAddress != address(0)) {
            console.log(string.concat(contractKey," already deployed to:"), previousAddress);
        } else {
            console.log(string.concat("Deploying ", contractKey, "..."));
            newAddress = address(new AccessControlSingleton());
            _writeAddress(contractKey, newAddress);
            console.log(string.concat(contractKey, " deployed to:"), newAddress);
        }

        contractKey = "AccessControlSingleton-Proxy";
        previousAddress = _readAddress(contractKey);        
        if (previousAddress != address(0)) {
            console.log(string.concat(contractKey," already deployed to:"), previousAddress);
        } else {
            console.log(string.concat("Deploying ", contractKey, "..."));
            newAddress = _deployUUPSProxy(
                newAddress,
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize(address)"))), admin
                )
            );
            _writeAddress(contractKey, newAddress);
            console.log(string.concat(contractKey, " deployed to:"), newAddress);
        }
        accessControl = newAddress;

        /// FRANCHISE REGISTRY
        contractKey = "FranchiseRegistry-Impl";
        previousAddress = _readAddress(contractKey);        
        if (previousAddress != address(0)) {
            console.log(string.concat(contractKey," already deployed to:"), previousAddress);
        } else {
            console.log(string.concat("Deploying ", contractKey, "..."));
            newAddress = address(new FranchiseRegistry(ipAssetsFactory));
            _writeAddress(contractKey, newAddress);
            console.log(string.concat(contractKey, " deployed to:"), newAddress);
        }

        contractKey = "FranchiseRegistry-Proxy";
        previousAddress = _readAddress(contractKey);        
        if (previousAddress != address(0)) {
            console.log(string.concat(contractKey," already deployed to:"), previousAddress);
        } else {
            console.log(string.concat("Deploying ", contractKey, "..."));
            newAddress = _deployUUPSProxy(
                newAddress,
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize(address)"))), accessControl
                )
            );
            _writeAddress(contractKey, newAddress);
            console.log(string.concat(contractKey, " deployed to:"), newAddress);
        }
        franchiseRegistry = newAddress;

        /// PROTOCOL RELATIONSHIP MODULE
        contractKey = "ProtocolRelationshipModule-Impl";
        previousAddress = _readAddress(contractKey);        
        if (previousAddress != address(0)) {
            console.log(string.concat(contractKey," already deployed to:"), previousAddress);
        } else {
            console.log(string.concat("Deploying ", contractKey, "..."));
            newAddress = address(new ProtocolRelationshipModule(franchiseRegistry));
            _writeAddress(contractKey, newAddress);
            console.log(string.concat(contractKey, " deployed to:"), newAddress);
        }

        contractKey = "ProtocolRelationshipModule-Proxy";
        previousAddress = _readAddress(contractKey);        
        if (previousAddress != address(0)) {
            console.log(string.concat(contractKey," already deployed to:"), previousAddress);
        } else {
            console.log(string.concat("Deploying ", contractKey, "..."));
            newAddress = _deployUUPSProxy(
                newAddress,
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize(address)"))), accessControl
                )
            );
            _writeAddress(contractKey, newAddress);
            console.log(string.concat(contractKey, " deployed to:"), newAddress);
        }

        _writeDeployment(); 
        if (block.chainid == 5) {
            vm.stopBroadcast();
        } else {
            vm.stopPrank();
        }
    }

}
*/