// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "script/foundry/utils/StringUtil.sol";


contract JsonDeploymentHandler is Script {

    using StringUtil for uint256;
    using stdJson for string;

    string contractOutput;
    uint256 contracts;

    constructor(string memory _initialContractOutput) {
        contractOutput = _initialContractOutput;
    }

    function _writeAddress(string memory contractKey, address newAddress) internal {
        contractOutput = vm.serializeAddress("", contractKey, newAddress);
        contracts++;
    }

    function _writeDeployment() internal {
        string memory chainId = (block.chainid).toString();
        contractOutput = vm.serializeUint("", "contracts", contracts);
        vm.writeJson(contractOutput, string.concat("./deployment-", chainId, ".json"));
    }

}
