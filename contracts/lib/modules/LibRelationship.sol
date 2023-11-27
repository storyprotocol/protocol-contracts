// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

/// @title Relationship Module Library
library LibRelationship {
    enum Relatables {
        UNDEFINED,
        IPA,
        IPORG_ENTRY,
        LICENSE,
        ADDRESS,
        EXTERNAL_NFT
    }

    struct RelatedElements {
        Relatables src;
        Relatables dst;
    }

    struct Relationship {
        string relType;
        address srcAddress;
        address dstAddress;
        uint256 srcId;
        uint256 dstId;
    }

    struct AddRelationshipTypeParams {
        string relType;
        address ipOrg;
        RelatedElements allowedElements;
        uint8[] allowedSrcs;
        uint8[] allowedDsts;
    }

    struct RelationshipType {
        address src;
        uint256 srcSubtypesMask;
        address dst;
        uint256 dstSubtypesMask;
    }

    struct CreateRelationshipParams {
        string relType;
        address srcAddress; 
        uint srcId;
        address dstAddress;
        uint dstId;
    }

    address public constant PROTOCOL_LEVEL_RELATIONSHIP = address(0);
    address public constant NO_ADDRESS_RESTRICTIONS = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;

    bytes32 public constant ADD_REL_TYPE_CONFIG = keccak256("ADD_REL_TYPE");
    bytes32 public constant REMOVE_REL_TYPE_CONFIG = keccak256("REMOVE_REL_TYPE");

}
