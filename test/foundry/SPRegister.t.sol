// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import './utils/ProxyHelper.sol';
import "../../contracts/SPRegister.sol";
import "../../contracts/sp-assets/SPAssetNFTFactory.sol";

contract SPRegisterTest is Test, ProxyHelper {
    SPAssetNFTFactory public factory;
    SPRegister public register;
    address admin;

    function setUp() public {
        factory = new SPAssetNFTFactory();
        register = SPRegister(
            _deployUUPSProxy(
                address(
                    new SPRegister(address(factory))
                ),
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize()")))
                )
            )
        );
    }

    function testInitialization() public {
        assertFalse(register.rootFranchiseAddress() == address(0));
        assertEq(register.rootFranchise().name, "Story Protocol");
        assertEq(register.rootFranchise().description, "The nexus of the narrative multiverse");
        assertEq(register.rootFranchise().url, "https://story-protocol.io");
        assertEq(uint(register.rootFranchise().regType), uint(SPRegister.RegisterType.FRANCHISE));
    }

}
