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

    struct Relationship {
        string relType;
        address srcAddress;
        address dstAddress;
        uint256 srcId;
        uint256 dstId;
    }

    address public constant PROTOCOL_LEVEL_RELATIONSHIP = address(0);

    bytes4 public constant ADD_REL_TYPE_SELECTOR =
        bytes4(
            keccak256(
                "_addRelationshipType((string,address,(uint8,uint8),uint8[],uint8[]))"
            )
        );
    bytes4 public constant REMOVE_REL_TYPE_SELECTOR =
        bytes4(keccak256("_removeRelationshipType(address,string)"));
    bytes4 public constant LOL = bytes4(keccak256("_lol(address)"));
}
