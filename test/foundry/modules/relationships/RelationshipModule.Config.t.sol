// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import 'test/foundry/utils/BaseTest.sol';
import 'contracts/modules/relationships/RelationshipModule.sol';
import 'contracts/lib/modules/LibRelationship.sol';
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { BitMask } from "contracts/lib/BitMask.sol";

contract RelationshipModuleConfigTest is BaseTest {

    address relCreator = address(4444444);

    function setUp() override public {
        super.setUp();
        _grantRole(vm, AccessControl.RELATIONSHIP_MANAGER_ROLE, relCreator);
    }

    function test_RelationshipModule_addProtocolRelationshipType() public {
        LibRelationship.RelatedElements memory allowedElements = LibRelationship.RelatedElements({
            src: LibRelationship.Relatables.Address,
            dst: LibRelationship.Relatables.Address
        });
        uint8[] memory allowedSrcs = new uint8[](0);
        uint8[] memory allowedDsts = new uint8[](0);
        LibRelationship.AddRelationshipTypeParams memory params = LibRelationship.AddRelationshipTypeParams({
            relType: "TEST_RELATIONSHIP",
            ipOrg: LibRelationship.PROTOCOL_LEVEL_RELATIONSHIP,
            allowedElements: allowedElements,
            allowedSrcs: allowedSrcs,
            allowedDsts: allowedDsts
        });
        vm.prank(relCreator);
        // Todo test event
        spg.addRelationshipType(params);
        LibRelationship.RelationshipType memory relType = relationshipModule.getRelationshipType(
            LibRelationship.PROTOCOL_LEVEL_RELATIONSHIP,
            "TEST_RELATIONSHIP"
        );
        assertEq(relType.src, LibRelationship.NO_ADDRESS_RESTRICTIONS);
        assertEq(relType.srcSubtypesMask, 0);
        assertEq(relType.dst, LibRelationship.NO_ADDRESS_RESTRICTIONS);
        assertEq(relType.dstSubtypesMask, 0);
    }

    function test_RelationshipModule_addIpOrgIpOrgRelationships() public {
        LibRelationship.RelatedElements memory allowedElements = LibRelationship.RelatedElements({
            src: LibRelationship.Relatables.IpOrgEntry,
            dst: LibRelationship.Relatables.IpOrgEntry
        });
        uint8[] memory allowedSrcs = new uint8[](2);
        allowedSrcs[0] = 0;
        allowedSrcs[1] = 2;
        uint8[] memory allowedDsts = new uint8[](1);
        allowedDsts[0] = 1;
        LibRelationship.AddRelationshipTypeParams memory params = LibRelationship.AddRelationshipTypeParams({
            relType: "TEST_RELATIONSHIP",
            ipOrg: address(ipOrg),
            allowedElements: allowedElements,
            allowedSrcs: allowedSrcs,
            allowedDsts: allowedDsts
        });
        vm.prank(ipOrgOwner);
        // Todo test event
        spg.addRelationshipType(params);
        LibRelationship.RelationshipType memory relType = relationshipModule.getRelationshipType(
            address(ipOrg),
            "TEST_RELATIONSHIP"
        );
        assertEq(relType.src, address(ipOrg));
        assertEq(relType.srcSubtypesMask, BitMask.convertToMask(allowedSrcs));
        assertEq(relType.dst, address(ipOrg));
        assertEq(relType.dstSubtypesMask, BitMask.convertToMask(allowedDsts));

    }

    function test_RelationshipModule_revert_addIpOrgIpOrgRelationships_UnsupportedTypes() public {
        uint8[] memory allowedSrcs = new uint8[](0);
        uint8[] memory allowedDsts = new uint8[](0);
        allowedSrcs = new uint8[](3);
        allowedSrcs[0] = 1;
        allowedSrcs[1] = 2;
        allowedSrcs[2] = 0;
        allowedDsts = new uint8[](1);
        allowedDsts[0] = 9;

        LibRelationship.RelatedElements memory allowedElements = LibRelationship.RelatedElements({
            src: LibRelationship.Relatables.IpOrgEntry,
            dst: LibRelationship.Relatables.IpOrgEntry
        });
        
        LibRelationship.AddRelationshipTypeParams memory params = LibRelationship.AddRelationshipTypeParams({
            relType: "TEST_RELATIONSHIP",
            ipOrg: address(ipOrg),
            allowedElements: allowedElements,
            allowedSrcs: allowedSrcs,
            allowedDsts: allowedDsts
        });
        vm.prank(ipOrgOwner);
        // Todo test event
        vm.expectRevert(Errors.RelationshipModule_UnsupportedIpOrgIndexType.selector);
        spg.addRelationshipType(params);
    }

    function test_RelationshipModule_revert_RelationshipModule_CallerNotIpOrgOwner() public {
        LibRelationship.RelatedElements memory allowedElements = LibRelationship.RelatedElements({
            src: LibRelationship.Relatables.IpOrgEntry,
            dst: LibRelationship.Relatables.IpOrgEntry
        });
        uint8[] memory allowedSrcs = new uint8[](2);
        allowedSrcs[0] = 0;
        allowedSrcs[1] = 2;
        uint8[] memory allowedDsts = new uint8[](1);
        allowedDsts[0] = 1;
        LibRelationship.AddRelationshipTypeParams memory params = LibRelationship.AddRelationshipTypeParams({
            relType: "TEST_RELATIONSHIP",
            ipOrg: address(ipOrg),
            allowedElements: allowedElements,
            allowedSrcs: allowedSrcs,
            allowedDsts: allowedDsts
        });
        vm.expectRevert(Errors.RelationshipModule_CallerNotIpOrgOwner.selector);
        spg.addRelationshipType(params);
    }

    function test_RelationshipModule_revert_ipOrgRelatableCannotBeProtocolLevel() public {
        LibRelationship.RelatedElements memory allowedElements = LibRelationship.RelatedElements({
            src: LibRelationship.Relatables.IpOrgEntry,
            dst: LibRelationship.Relatables.IpOrgEntry
        });
        uint8[] memory allowedSrcs = new uint8[](1);
        allowedSrcs[0] = 1;
        uint8[] memory allowedDsts = new uint8[](1);
        allowedDsts[0] = 0;
        LibRelationship.AddRelationshipTypeParams memory params = LibRelationship.AddRelationshipTypeParams({
            relType: "TEST_RELATIONSHIP",
            ipOrg: LibRelationship.PROTOCOL_LEVEL_RELATIONSHIP,
            allowedElements: allowedElements,
            allowedSrcs: allowedSrcs,
            allowedDsts: allowedDsts
        });
        vm.prank(relCreator);
        // Todo test event
        vm.expectRevert(Errors.RelationshipModule_IpOrgRelatableCannotBeProtocolLevel.selector);
        spg.addRelationshipType(params);
    }

    function test_RelationshipModule_removeProtocolRelationshipType() public {
        LibRelationship.RelatedElements memory allowedElements = LibRelationship.RelatedElements({
            src: LibRelationship.Relatables.Address,
            dst: LibRelationship.Relatables.Address
        });
        uint8[] memory allowedSrcs = new uint8[](0);
        uint8[] memory allowedDsts = new uint8[](0);
        LibRelationship.AddRelationshipTypeParams memory params = LibRelationship.AddRelationshipTypeParams({
            relType: "TEST_RELATIONSHIP",
            ipOrg: LibRelationship.PROTOCOL_LEVEL_RELATIONSHIP,
            allowedElements: allowedElements,
            allowedSrcs: allowedSrcs,
            allowedDsts: allowedDsts
        });
        vm.startPrank(relCreator);
        // Todo test event
        spg.addRelationshipType(params);
        spg.removeRelationshipType(LibRelationship.PROTOCOL_LEVEL_RELATIONSHIP, "TEST_RELATIONSHIP");
        vm.stopPrank();
        vm.expectRevert(abi.encodeWithSignature("RelationshipModule_RelTypeNotSet(string)", "TEST_RELATIONSHIP"));
        LibRelationship.RelationshipType memory relType = relationshipModule.getRelationshipType(
            LibRelationship.PROTOCOL_LEVEL_RELATIONSHIP,
            "TEST_RELATIONSHIP"
        );        assertEq(relType.src, address(0));
    }


}

