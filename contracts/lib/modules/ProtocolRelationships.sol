// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { LibRelationship } from "contracts/lib/modules/LibRelationship.sol";

library ProtocolRelationships {

    string constant public IPORG_TERMS_REL_TYPE = "IPORG_TERMS";

    function _getIpOrgTermsAddRelParams()
        internal pure 
        returns (LibRelationship.AddRelationshipTypeParams memory) {
        return LibRelationship.AddRelationshipTypeParams({
            relType: IPORG_TERMS_REL_TYPE,
            ipOrg: LibRelationship.PROTOCOL_LEVEL_RELATIONSHIP,
            allowedElements: LibRelationship.RelatedElements({
                src: LibRelationship.Relatables.ADDRESS,
                dst: LibRelationship.Relatables.LICENSE
            }),
            allowedSrcs: new uint8[](0),
            allowedDsts: new uint8[](0)
        });
    }

    string constant public IPA_LICENSE_REL_TYPE = "IPA_LICENSE";

    function _getIpLicenseAddRelPArams()
        internal pure 
        returns (LibRelationship.AddRelationshipTypeParams memory) {
        return LibRelationship.AddRelationshipTypeParams({
            relType: IPA_LICENSE_REL_TYPE,
            ipOrg: LibRelationship.PROTOCOL_LEVEL_RELATIONSHIP,
            allowedElements: LibRelationship.RelatedElements({
                src: LibRelationship.Relatables.IPA,
                dst: LibRelationship.Relatables.LICENSE
            }),
            allowedSrcs: new uint8[](0),
            allowedDsts: new uint8[](0)
        });
    }


    string constant public SUBLICENSE_REL_TYPE = "SUBLICENSE";

    function _getSublicenseAddRelParams()
        internal pure 
        returns (LibRelationship.AddRelationshipTypeParams memory) {
        return LibRelationship.AddRelationshipTypeParams({
            relType: SUBLICENSE_REL_TYPE,
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