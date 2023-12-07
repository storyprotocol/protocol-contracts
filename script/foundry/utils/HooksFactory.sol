// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
import { Hook } from "contracts/lib/hooks/Hook.sol";

contract HooksFactory {
    function deploy(bytes memory code_, uint256 hookTypeFlag_, uint256 seed_) external returns (address hookAddr) {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(seed_)));
        for (uint256 i = 0; i < 1500; i++) {
            bytes32 salt = bytes32(randomNumber + i);
            bytes32 bytecodeHash = keccak256(code_);
            address expectedAddress = Create2.computeAddress(salt, bytecodeHash);
            uint160 prefix = hookTypeFlag_ == Hook.SYNC_FLAG ? 0x02 : 0x01;
            if (_doesAddressStartWith(expectedAddress, prefix)) {
                hookAddr = Create2.deploy(0, salt, code_);
                return hookAddr;
            }
        }
    }

    function _doesAddressStartWith(address address_,uint160 prefix_) private pure returns (bool) {
        return uint160(address_) >> (160 - 2) == prefix_;
    }
}