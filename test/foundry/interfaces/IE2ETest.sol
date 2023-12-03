// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { HookResult } from "contracts/interfaces/hooks/base/IHook.sol";
import { LibRelationship } from "contracts/lib/modules/LibRelationship.sol";
import { HookRegistry } from "contracts/modules/base/HookRegistry.sol";

interface IE2ETest {
    //
    // RegistrationModule events
    //

    event MetadataUpdated(
        address indexed ipOrg_,
        string baseURI_,
        string contractURI_
    );

    event IPAssetRegistered(
        uint256 ipAssetId_,
        address indexed ipOrg_,
        uint256 ipOrgAssetId_,
        address indexed owner_,
        string name_,
        uint8 indexed ipOrgAssetType_,
        bytes32 hash_,
        string mediaUrl_
    );

    event IPAssetTransferred(
        uint256 indexed ipAssetId_,
        address indexed ipOrg_,
        uint256 ipOrgAssetId_,
        address prevOwner_,
        address newOwner_
    );

    //
    // RelationshipModule events
    //

    event RelationshipTypeSet(
        string relType,
        address indexed ipOrg,
        address src,
        LibRelationship.Relatables srcRelatable,
        uint256 srcSubtypesMask,
        address dst,
        LibRelationship.Relatables dstRelatable,
        uint256 dstSubtypesMask
    );

    event RelationshipTypeUnset(
        string relType,
        address ipOrg
    );

    event RelationshipCreated(
        uint256 indexed relationshipId,
        string relType,
        address srcAddress,
        uint256 srcId,
        address dstAddress,
        uint256 dstId
    );

    //
    // HookRegistry events
    //

    event HooksRegistered(
        HookRegistry.HookType indexed hType,
        bytes32 indexed registryKey,
        address[] hooks
    );
    event HooksCleared(
        HookRegistry.HookType indexed hType,
        bytes32 indexed registryKey
    );

    //
    // TermsRepository events
    //

    event TermCategoryAdded(string category);
    event TermCategoryRemoved(string category);
    event TermAdded(string category, string termId);
    event TermDisabled(string category, string termId);

    //
    // SyncHook events
    //

    event SyncHookExecuted(
        address indexed hookAddress,
        HookResult indexed result,
        bytes contextData,
        bytes returnData
    );
}
