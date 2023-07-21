// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "script/foundry/utils/StringUtil.sol";


contract JsonDeploymentHandler is Script {

    using StringUtil for uint256;
    using stdJson for string;

    string contractOutput;
    bool printFinalJson;
    string chainId = (block.chainid).toString();

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

    function _readAddress(string memory contractName) internal returns(address) {
        try vm.parseJsonAddress(contractOutput, string.concat("$.", chainId,".", contractName)) returns (address addr) {
            return addr;
        } catch  {
            return address(0);
        }
    }

    function _writeDeployment() internal {
        string memory finalJson = chainId.serialize(chainId, contractOutput);
        if (block.chainid == 5) {
            vm.writeJson(finalJson, "./deployment-public.json");
        } else {
            vm.writeJson(finalJson, "./deployment-local.json");
        }
    }

}
