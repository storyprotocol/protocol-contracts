// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { Registration } from "contracts/lib/modules/Registration.sol";

/// @title IRegistrationModule
interface IRegistrationModule {

    /// @notice Emits when an IPOrg updates metadata associated with its IPA.
    event MetadataUpdated(
        address indexed ipOrg,
        string memory baseURI,
        string memory contractURI
    )

    event IPAssetRegistered(
        uint256 ipAssetId,
        address indexed owner,
        address indexed ipOrg,
        uint256 ipOrgAssetId
    )

    /// Emitted with a new Relationship Type definitions is created
    event RelationshipTypeSet(
        // Short string naming the type
        string indexed relType,
        // Zero for protocol-wide, or address of the IPOrg
        address indexed ipOrg,
        // Allowed src address, zero address if empty, all F for all addresses are OK
        address src,
        // Allowed items for src
        LibRelationship.Relatables srcRelatable,
        // Mask of allowed subtypes for src (see LibUintArrayMask)
        uint256 srcSubtypesMask,
        // Allowed dst address, zero address if empty, all F for all addresses are OK
        address dst,
        // Allowed items for dst
        LibRelationship.Relatables dstRelatable,
        // Mask of allowed subtypes for dst (see LibUintArrayMask)
        uint256 dstSubtypesMask
    );

    /// Emitted when a Relationship Type definition is removed
    event RelationshipTypeUnset(
        // Short string naming the type
        string indexed relType,
        // Zero for protocol-wide, or address of the IPOrg
        address ipOrg
    );

    /// Emitted when a Relationship is created, linking 2 elements
    event RelationshipCreated(
        // Sequential Relationship ID
        uint256 indexed relationshipId,
        // Short string naming the type
        string indexed relType,
        // Source contract or EOA
        address srcAddress,
        // Source item ID
        uint256 srcId,
        // Destination contract or EOA
        address dstAddress,
        // Destination item ID
        uint256 dstId
    );

    /// Gets relationship type definition for a given relationship type name
    /// Will revert if no relationship type is found
    /// @param ipOrg_ IP Org address or zero address for protocol level relationships
    /// @param relType_ the name of the relationship type
    /// @return result the relationship type definition
    function getRelationshipType(address ipOrg_, string memory relType_) external view returns (LibRelationship.RelationshipType memory);
    /// Gets relationship definition for a given relationship id
    function getRelationship(uint256 relationshipId_) external view returns (LibRelationship.Relationship memory);
    /// Gets relationship id for a given relationship
    function getRelationshipId(LibRelationship.Relationship calldata rel_) external view returns (uint256);
    /// Checks if a relationship has been set
    function relationshipExists(LibRelationship.Relationship calldata rel_) external view returns (bool);   
}
