// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import 'test/foundry/utils/BaseTest.sol';
import 'contracts/modules/relationships/RelationshipModule.sol';
import 'contracts/lib/modules/LibRelationship.sol';
import { AccessControl } from "contracts/lib/AccessControl.sol";

contract RelationshipModuleSettingTest is BaseTest {

    address relCreator = address(4444444);

    function setUp() override public {
        super.setUp();
        _grantRole(vm, AccessControl.RELATIONSHIP_MANAGER_ROLE, relCreator);
        LibRelationship.RelatedElements memory allowedElements = LibRelationship.RelatedElements({
            src: LibRelationship.Relatables.ADDRESS,
            dst: LibRelationship.Relatables.ADDRESS
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
    }

    function test_RelationshipModule_createRelationshipAddressToAddress() public {
        LibRelationship.CreateRelationshipParams memory params = LibRelationship.CreateRelationshipParams({
            relType: "TEST_RELATIONSHIP",
            srcAddress: address(1111111),
            srcId: 0,
            dstAddress: address(2222222),
            dstId: 0
        });
        bytes[] memory preHooksData = new bytes[](0);
        bytes[] memory postHooksData = new bytes[](0);
        uint256 id = spg.createRelationship(LibRelationship.PROTOCOL_LEVEL_RELATIONSHIP, params, preHooksData, postHooksData);
        assertEq(id, 1);
        LibRelationship.Relationship memory rel = relationshipModule.getRelationship(1);
        assertEq(rel.relType, "TEST_RELATIONSHIP");
        assertEq(rel.srcAddress, address(1111111));
        assertEq(rel.dstAddress, address(2222222));
        assertEq(rel.srcId, 0);
        assertEq(rel.dstId, 0);
        assertEq(relationshipModule.getRelationshipId(rel), 1);
    }


}

