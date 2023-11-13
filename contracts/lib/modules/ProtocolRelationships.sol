// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { LibRelationship } from "contracts/lib/modules/LibRelationship.sol";

library ProtocolRelationships {

    string constant public IPA_LICENSE = "IPA_LICENSE";

    function _getIpLicenseAddRelPArams()
        internal pure 
        returns (LibRelationship.AddRelationshipTypeParams memory) {
        return LibRelationship.AddRelationshipTypeParams({
            relType: IPA_LICENSE,
            ipOrg: LibRelationship.PROTOCOL_LEVEL_RELATIONSHIP,
            allowedElements: LibRelationship.RelatedElements({
                src: LibRelationship.Relatables.LICENSE,
                dst: LibRelationship.Relatables.IPA
            }),
            allowedSrcs: new uint8[](0),
            allowedDsts: new uint8[](0)
        });
    }


    string constant public SUBLICENSE_OF = "SUBLICENSE_OF";

    function _getSublicenseAddRelParams()
        internal pure 
        returns (LibRelationship.AddRelationshipTypeParams memory) {
        return LibRelationship.AddRelationshipTypeParams({
            relType: SUBLICENSE_OF,
            ipOrg: LibRelationship.PROTOCOL_LEVEL_RELATIONSHIP,
            allowedElements: LibRelationship.RelatedElements({
                src: LibRelationship.Relatables.LICENSE,
                dst: LibRelationship.Relatables.LICENSE
            }),
            allowedSrcs: new uint8[](0),
            allowedDsts: new uint8[](0)
        });
    }


}