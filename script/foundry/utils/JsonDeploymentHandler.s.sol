// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "script/foundry/utils/StringUtil.sol";


contract JsonDeploymentHandler is Script {

    using StringUtil for uint256;
    using stdJson for string;

    string contractOutput;
    uint256 contracts;
    string chainId;

    constructor(string memory _initialContractOutput) {
        contractOutput = _initialContractOutput;
        chainId = (block.chainid).toString();
    }

    function _writeAddress(string memory contractKey, address newAddress) internal {
        contractOutput = vm.serializeAddress("", contractKey, newAddress);
        contractOutput = vm.serializeUint("", "contracts", contracts++);
    }

    function _readAddress(string memory contractName) internal returns(address) {
        try vm.parseJsonAddress(contractOutput, string.concat("$.", contractName)) returns (address addr) {
            return addr;
        } catch  {
            return address(0);
        }
    }

    function _readDeployment() internal {
        if (bytes(contractOutput).length == 0) {
            string memory root = vm.projectRoot();
            string memory filePath = string.concat("/deployment-", (block.chainid).toString(), ".json");
            string memory path = string.concat(root, filePath);
            contractOutput = vm.readFile(path);
        }
        contracts = vm.parseJsonUint(contractOutput, "$.contracts");
    }

    function _writeDeployment() internal {
        vm.writeJson(contractOutput, string.concat("./deployment-", chainId, ".json"));
    }

}
