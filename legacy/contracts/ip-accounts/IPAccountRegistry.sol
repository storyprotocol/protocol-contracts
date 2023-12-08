// SPDX-License-Identifier: UNLICENSED
// See Story Protocol Alpha Agreement: https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.13;

import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
import { IIPAccountRegistry } from "contracts/interfaces/ip-accounts/IIPAccountRegistry.sol";
import { Errors } from "contracts/lib/Errors.sol";

contract IPAccountRegistry is IIPAccountRegistry {
    address internal immutable IP_ACCOUNT_IMPL;
    uint256 internal immutable IP_ACCOUNT_SALT;

    constructor(address ipAccountImpl_) {
        if (ipAccountImpl_ == address(0)) revert Errors.IPAccountRegistry_NonExistentIpAccountImpl();
        IP_ACCOUNT_IMPL = ipAccountImpl_;
        IP_ACCOUNT_SALT = 0;
    }

    function createAccount(
        uint256 chainId_,
        address tokenContract_,
        uint256 tokenId_,
        bytes calldata initData_
    ) external returns (address) {
        bytes memory code = _getCreationCode(
            IP_ACCOUNT_IMPL,
            chainId_,
            tokenContract_,
            tokenId_,
            IP_ACCOUNT_SALT
        );

        address _account = Create2.computeAddress(
            bytes32(IP_ACCOUNT_SALT),
            keccak256(code)
        );

        if (_account.code.length != 0) return _account;

        emit AccountCreated(
            _account,
            IP_ACCOUNT_IMPL,
            chainId_,
            tokenContract_,
            tokenId_,
            IP_ACCOUNT_SALT
        );

        _account = Create2.deploy(0, bytes32(IP_ACCOUNT_SALT), code);

        if (initData_.length != 0) {
            (bool success, ) = _account.call(initData_);
            if (!success) revert Errors.IPAccountRegistry_InitializationFailed();
        }

        return _account;
    }

    function account(
        uint256 chainId_,
        address tokenContract_,
        uint256 tokenId_
    ) external view returns (address) {
        bytes32 bytecodeHash = keccak256(
            _getCreationCode(
                IP_ACCOUNT_IMPL,
                chainId_,
                tokenContract_,
                tokenId_,
                IP_ACCOUNT_SALT
            )
        );

        return Create2.computeAddress(bytes32(0), bytecodeHash);
    }

    /// @inheritdoc IIPAccountRegistry
    function getIpAccountImpl() external view override returns (address) {
        return IP_ACCOUNT_IMPL;
    }

    function _getCreationCode(
        address implementation_,
        uint256 chainId_,
        address tokenContract_,
        uint256 tokenId_,
        uint256 salt_
    ) internal pure returns (bytes memory) {
        // Proxy that delegate call to IPAccountProxy
        //    |           0x00000000      36             calldatasize          cds
        //    |           0x00000001      3d             returndatasize        0 cds
        //    |           0x00000002      3d             returndatasize        0 0 cds
        //    |           0x00000003      37             calldatacopy
        //    |           0x00000004      3d             returndatasize        0
        //    |           0x00000005      3d             returndatasize        0 0
        //    |           0x00000006      3d             returndatasize        0 0 0
        //    |           0x00000007      36             calldatasize          cds 0 0 0
        //    |           0x00000008      3d             returndatasize        0 cds 0 0 0
        //    |           0x00000009      73bebebebebe.  push20 0xbebebebe     0xbebe 0 cds 0 0 0
        //    |           0x0000001e      5a             gas                   gas 0xbebe 0 cds 0 0 0
        //    |           0x0000001f      f4             delegatecall          suc 0
        //    |           0x00000020      3d             returndatasize        rds suc 0
        //    |           0x00000021      82             dup3                  0 rds suc 0
        //    |           0x00000022      80             dup1                  0 0 rds suc 0
        //    |           0x00000023      3e             returndatacopy        suc 0
        //    |           0x00000024      90             swap1                 0 suc
        //    |           0x00000025      3d             returndatasize        rds 0 suc
        //    |           0x00000026      91             swap2                 suc 0 rds
        //    |           0x00000027      602b           push1 0x2b            0x2b suc 0 rds
        //    |       ,=< 0x00000029      57             jumpi                 0 rds
        //    |       |   0x0000002a      fd             revert
        //    |       `-> 0x0000002b      5b             jumpdest              0 rds
        //    \           0x0000002c      f3             return
        return
            abi.encodePacked(
                hex"3d60ad80600a3d3981f3363d3d373d3d3d363d73",
                implementation_,
                hex"5af43d82803e903d91602b57fd5bf3",
                abi.encode(salt_, chainId_, tokenContract_, tokenId_)
            );
    }
}
