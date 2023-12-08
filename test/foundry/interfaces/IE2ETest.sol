// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { HookResult } from "contracts/interfaces/hooks/base/IHook.sol";
import { LibRelationship } from "contracts/lib/modules/LibRelationship.sol";
import { Licensing } from "contracts/lib/modules/Licensing.sol";
import { HookRegistry } from "contracts/modules/base/HookRegistry.sol";
import { ShortString } from "@openzeppelin/contracts/utils/ShortStrings.sol";

interface IE2ETest {
    //
    // Registration Module
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
    // IModule
    //

    event RequestPending(address indexed sender);
    event RequestCompleted(address indexed sender);
    event RequestFailed(address indexed sender, string reason);

    //
    // Relationship Module
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

    event RelationshipTypeUnset(string relType, address ipOrg);

    event RelationshipCreated(
        uint256 indexed relationshipId,
        string relType,
        address srcAddress,
        uint256 srcId,
        address dstAddress,
        uint256 dstId
    );

    //
    // Licensing
    //

    event IpOrgLicensingFrameworkSet(
        address indexed ipOrg,
        string frameworkId,
        string url,
        Licensing.LicensorConfig licensorConfig
    );

    event FrameworkAdded(string frameworkId, string textUrl);

    event ParamDefinitionAdded(
        string frameworkId,
        ShortString tag,
        Licensing.ParameterType paramType
    );

    event LicenseRegistered(uint256 indexed id);
    event LicenseNftLinkedToIpa(
        uint256 indexed licenseId,
        uint256 indexed ipAssetId
    );
    event LicenseActivated(uint256 indexed licenseId);
    event LicenseRevoked(uint256 indexed licenseId);

    //
    // HookRegistry
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
    // IPAssetRegistry
    //

    event Registered(
        uint256 ipAssetId_,
        string name_,
        address indexed ipOrg_,
        address indexed registrant_,
        bytes32 hash_
    );

    event IPOrgTransferred(
        uint256 indexed ipAssetId_,
        address indexed oldIPOrg_,
        address indexed newIPOrg_
    );

    event StatusChanged(
        uint256 indexed ipAssetId_,
        uint8 oldStatus_,
        uint8 newStatus_
    );

    //
    // Sync Hooks
    //

    event SyncHookExecuted(
        address indexed hookAddress,
        HookResult indexed result,
        bytes contextData,
        bytes returnData
    );

    //
    // Async Hooks
    //

    event AsyncHookExecuted(
        address indexed hookAddress,
        address indexed callbackHandler,
        HookResult indexed result,
        bytes32 requestId,
        bytes contextData,
        bytes returnData
    );

    event AsyncHookCalledBack(
        address indexed hookAddress,
        address indexed callbackHandler,
        bytes32 requestId,
        bytes callbackData
    );

    //
    // Polygon Token Hook
    //

    event PolygonTokenBalanceRequest(
        bytes32 indexed requestId,
        address indexed requester,
        address tokenAddress,
        address tokenOwnerAddress,
        address callbackAddr,
        bytes4 callbackFunctionSignature
    );
}
