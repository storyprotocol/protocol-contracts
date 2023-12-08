// SPDX-License-Identifier: UNLICENSED
// See https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.19;

/// @title Relationship Module Library
library LibRelationship {
    /// @notice defines the elements that can be related in a relationship type
    enum Relatables {
        /// Unset value
        Undefined,
        /// The relationship type can be used to relate IPAs
        Ipa,
        /// The relationship type can be used to relate IPOrg token ids
        IpOrgEntry,
        /// The relationship type can be used to relate License token ids
        License,
        /// The relationship type can be used to relate Addresses
        Address,
        /// The relationship type can be used to relate External NFTs (e.g. ERC721)
        ExternalNft
    }

    /// @notice defines the elements that can be related in a relationship type
    struct RelatedElements {
        /// Source type
        Relatables src;
        /// Destination type
        Relatables dst;
    }

    /// @notice defines 2 related elements under a certain type
    struct Relationship {
        /// Relationship type name id
        string relType;
        /// Source address
        address srcAddress;
        /// Destination address
        address dstAddress;
        /// Source id (or zero if not applicable)
        uint256 srcId;
        /// Destination id (or zero if not applicable)
        uint256 dstId;
    }

    /// @notice defines the parameters for adding a relationship type
    struct AddRelationshipTypeParams {
        /// Relationship type name id
        string relType;
        /// IP Org address or zero address for protocol level rel types
        address ipOrg;
        /// Source and destination types
        RelatedElements allowedElements;
        /// Source ipOrgs types allowed or empty array if not applicable
        uint8[] allowedSrcs;
        /// Destination ipOrgs types allowed or empty array if not applicable
        uint8[] allowedDsts;
    }

    /// @notice defines the parameters to define a relationship type
    struct RelationshipType {
        /// Allowed source address
        address src;
        /// Allowd source subtypes (bitmask verion of allowedSrcs)
        uint256 srcSubtypesMask;
        /// Allowed destination address
        address dst;
        /// Allowed destination subtypes (bitmask verion of allowedDsts)
        uint256 dstSubtypesMask;
    }

    /// @notice defines the parameters for creating a relationship
    struct CreateRelationshipParams {
        /// Relationship type name id
        string relType;
        /// Source address
        address srcAddress;
        /// Source id or zero if not applicable
        uint256 srcId;
        /// Destination address
        address dstAddress;
        /// Destination id or zero if not applicable
        uint256 dstId;
    }

    /// Constant for protocol level relationship types
    address public constant PROTOCOL_LEVEL_RELATIONSHIP = address(0);
    /// Any address goes
    address public constant NO_ADDRESS_RESTRICTIONS = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;

    /// Action to configure a relationship type in Relationship Module
    bytes32 public constant ADD_REL_TYPE_CONFIG = keccak256("ADD_REL_TYPE");
    /// Action to remove a relationship type in Relationship Module
    bytes32 public constant REMOVE_REL_TYPE_CONFIG = keccak256("REMOVE_REL_TYPE");
}
