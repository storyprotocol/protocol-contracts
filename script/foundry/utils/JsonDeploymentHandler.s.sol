// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "script/foundry/utils/StringUtil.sol";


contract JsonDeploymentHandler is Script {

    using StringUtil for uint256;
    using stdJson for string;

    string contractOutput;
    string chainId = (block.chainid).toString();
    uint256 contracts;

    constructor(string memory _initialContractOutput) {
        contractOutput = _initialContractOutput;
    }

    function _readDeployment() internal {
        string memory root = vm.projectRoot();
        string memory filePath;
        if (block.chainid == 5) {
            filePath = "/deployment-public.json";
        } else {
            filePath = "/deployment-local.json";
        }
        string memory path = string.concat(root, filePath);
        contractOutput = vm.readFile(path);
    }


    function _writeAddress(string memory contractKey, address newAddress) internal {
        contractOutput = vm.serializeAddress("", contractKey, newAddress);
        contracts++;
    }

    function _writeDeployment() internal {
        contractOutput = vm.serializeUint("", "contracts", contracts);
        string memory output = vm.serializeString(contractOutput, chainId, contractOutput);
        
        if (block.chainid == 5) {
            vm.writeJson(output, "./deployment-public.json");
        } else {
            vm.writeJson(output, "./deployment-local.json");
        }
    }

}
