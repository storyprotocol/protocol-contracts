// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import 'test/foundry/utils/BaseTest.sol';
import 'contracts/modules/relationships/RelationshipModule.sol';
import 'contracts/lib/modules/LibRelationship.sol';
import { AccessControl } from "contracts/lib/AccessControl.sol";

contract RelationshipModuleConfigTest is BaseTest {

    function setUp() override public {
        super.setUp();
    }

    function test_RelationshipModule_addRelationshipType() public {
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
        spg.addRelationshipType(params);
    }
}

