/* solhint-disable contract-name-camelcase, func-name-mixedcase, var-name-mixedcase */
// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "test/foundry/utils/BaseTest.sol";
import "contracts/modules/relationships/RelationshipModule.sol";
import "contracts/lib/modules/LibRelationship.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";

contract RelationshipModuleSettingTest is BaseTest {
    address relCreator = address(4444444);
    address ipaOwner = address(123);

    function setUp() public override {
        super.setUp();
        _grantRole(vm, AccessControl.RELATIONSHIP_MANAGER_ROLE, relCreator);
    }

    function test_RelationshipModule_createAddressToAddress() public {
        _addRelType(
            LibRelationship.PROTOCOL_LEVEL_RELATIONSHIP,
            LibRelationship.Relatables.Address,
            LibRelationship.Relatables.Address,
            0
        );

        LibRelationship.CreateRelationshipParams memory params = LibRelationship
            .CreateRelationshipParams({
                relType: "TEST_RELATIONSHIP",
                srcAddress: address(1111111),
                srcId: 0,
                dstAddress: address(2222222),
                dstId: 0
            });
        bytes[] memory preHooksData = new bytes[](0);
        bytes[] memory postHooksData = new bytes[](0);
        uint256 id = spg.createRelationship(
            LibRelationship.PROTOCOL_LEVEL_RELATIONSHIP,
            params,
            preHooksData,
            postHooksData
        );
        assertEq(id, 1);
        LibRelationship.Relationship memory rel = relationshipModule
            .getRelationship(1);
        assertEq(rel.relType, "TEST_RELATIONSHIP");
        assertEq(rel.srcAddress, address(1111111));
        assertEq(rel.dstAddress, address(2222222));
        assertEq(rel.srcId, 0);
        assertEq(rel.dstId, 0);
        assertEq(relationshipModule.getRelationshipId(rel), 1);
    }

    function test_RelationshipModule_createIpOrgToIpOrg() public {
        _addRelType(
            address(ipOrg),
            LibRelationship.Relatables.IpOrgEntry,
            LibRelationship.Relatables.IpOrgEntry,
            2
        );
        (, uint256 localId) = _createIpAsset(ipaOwner, 1, bytes(""));
        (, uint256 localId2) = _createIpAsset(ipaOwner, 1, bytes(""));
        LibRelationship.CreateRelationshipParams memory params = LibRelationship
            .CreateRelationshipParams({
                relType: "TEST_RELATIONSHIP",
                srcAddress: address(ipOrg),
                srcId: localId,
                dstAddress: address(ipOrg),
                dstId: localId2
            });
        bytes[] memory preHooksData = new bytes[](0);
        bytes[] memory postHooksData = new bytes[](0);
        uint256 id = spg.createRelationship(
            address(ipOrg),
            params,
            preHooksData,
            postHooksData
        );
        assertEq(id, 1);
        LibRelationship.Relationship memory rel = relationshipModule
            .getRelationship(1);
        assertEq(rel.relType, "TEST_RELATIONSHIP");
        assertEq(rel.srcAddress, address(ipOrg));
        assertEq(rel.dstAddress, address(ipOrg));
        assertEq(rel.srcId, localId);
        assertEq(rel.dstId, localId2);
        assertEq(relationshipModule.getRelationshipId(rel), 1);
    }

    function test_RelationshipModule_revert_createIpOrgToIpOrg_InvalidSrcId()
        public
    {
        _addRelType(
            address(ipOrg),
            LibRelationship.Relatables.IpOrgEntry,
            LibRelationship.Relatables.IpOrgEntry,
            1
        );
        
        (, uint256 localId) = _createIpAsset(ipaOwner, 2, bytes(""));
        (, uint256 localId2) = _createIpAsset(ipaOwner, 1, bytes(""));
        LibRelationship.CreateRelationshipParams memory params = LibRelationship
            .CreateRelationshipParams({
                relType: "TEST_RELATIONSHIP",
                srcAddress: address(ipOrg),
                srcId: localId,
                dstAddress: address(ipOrg),
                dstId: localId2
            });
        bytes[] memory preHooksData = new bytes[](0);
        bytes[] memory postHooksData = new bytes[](0);
        vm.expectRevert(Errors.RelationshipModule_InvalidSrcId.selector);
        spg.createRelationship(
            address(ipOrg),
            params,
            preHooksData,
            postHooksData
        );
    }

    function test_RelationshipModule_createAddressToIpa() public {
        _addRelType(
            LibRelationship.PROTOCOL_LEVEL_RELATIONSHIP,
            LibRelationship.Relatables.Address,
            LibRelationship.Relatables.Ipa,
            0
        );
        (uint256 ipaId, ) = _createIpAsset(ipaOwner, 2, bytes(""));
        LibRelationship.CreateRelationshipParams memory params = LibRelationship
            .CreateRelationshipParams({
                relType: "TEST_RELATIONSHIP",
                srcAddress: address(1111111),
                srcId: 0,
                dstAddress: address(registry),
                dstId: ipaId
            });
        bytes[] memory preHooksData = new bytes[](0);
        bytes[] memory postHooksData = new bytes[](0);
        uint256 id = spg.createRelationship(
            LibRelationship.PROTOCOL_LEVEL_RELATIONSHIP,
            params,
            preHooksData,
            postHooksData
        );
        assertEq(id, 1);
        LibRelationship.Relationship memory rel = relationshipModule
            .getRelationship(1);
        assertEq(rel.relType, "TEST_RELATIONSHIP");
        assertEq(rel.srcAddress, address(1111111));
        assertEq(rel.dstAddress, address(registry));
        assertEq(rel.srcId, 0);
        assertEq(rel.dstId, ipaId);
        assertEq(relationshipModule.getRelationshipId(rel), 1);
    }

    function test_RelationshipModule_createExternalNftToExternalNft() public {
        _addRelType(
            LibRelationship.PROTOCOL_LEVEL_RELATIONSHIP,
            LibRelationship.Relatables.ExternalNft,
            LibRelationship.Relatables.ExternalNft,
            0
        );

        LibRelationship.CreateRelationshipParams memory params = LibRelationship
            .CreateRelationshipParams({
                relType: "TEST_RELATIONSHIP",
                srcAddress: address(1111111),
                srcId: 0,
                dstAddress: address(2222222),
                dstId: 0
            });
        bytes[] memory preHooksData = new bytes[](0);
        bytes[] memory postHooksData = new bytes[](0);
        uint256 id = spg.createRelationship(
            LibRelationship.PROTOCOL_LEVEL_RELATIONSHIP,
            params,
            preHooksData,
            postHooksData
        );
        assertEq(id, 1);
        LibRelationship.Relationship memory rel = relationshipModule
            .getRelationship(1);
        assertEq(rel.relType, "TEST_RELATIONSHIP");
        assertEq(rel.srcAddress, address(1111111));
        assertEq(rel.dstAddress, address(2222222));
        assertEq(rel.srcId, 0);
        assertEq(rel.dstId, 0);
        assertEq(relationshipModule.getRelationshipId(rel), 1);
    }

    function _addRelType(
        address ipOrg,
        LibRelationship.Relatables src,
        LibRelationship.Relatables dst,
        uint8 maxSrc
    ) internal {
        address caller = ipOrgOwner;
        uint8[] memory allowedSrcs = new uint8[](0);
        uint8[] memory allowedDsts = new uint8[](0);
        if (ipOrg == address(0)) {
            caller = relCreator;
        } else {
            allowedSrcs = new uint8[](3);
            for (uint8 i = 0; i < maxSrc; i++) {
                allowedSrcs[i] = uint8(i);
            }
            allowedDsts = new uint8[](1);
            allowedDsts[0] = 1;
        }
        LibRelationship.RelatedElements memory allowedElements = LibRelationship
            .RelatedElements({ src: src, dst: dst });

        LibRelationship.AddRelationshipTypeParams
            memory params = LibRelationship.AddRelationshipTypeParams({
                relType: "TEST_RELATIONSHIP",
                ipOrg: ipOrg,
                allowedElements: allowedElements,
                allowedSrcs: allowedSrcs,
                allowedDsts: allowedDsts
            });
        vm.prank(caller);
        // Todo test event
        spg.addRelationshipType(params);
    }
}
