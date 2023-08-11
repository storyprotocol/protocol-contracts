// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { LibTimeConditional } from "../timing/LibTimeConditional.sol";

contract LicensingModule {

    struct Token {
        IERC721 collection;
        uint256 tokenId;
    }

    struct License {
        bool active;

        Token licensedToken; // If this is not null, the license is non-transferable and the holder is this token.

        uint256 parentLicenseId;
        address licenseHolder; // If transferrable, this is the ERC721 owner
        bool tranferable; // If yes, assign an owner through ERC721
        bool transferableByParentOnly; // If yes, only the parent license can transfer the license

        bool exclusive;
        bool canSublicense; // TODO: consider sublicensing limitations (i.e can only sublicense for media X, etc.)
        bool commercial;

        // Contract defining the payment terms, royalties, milestones, etc.
        // The interpreter does not necessarily enforce the terms.
        address paymentTermsInterpreter;
        bytes paymentTermsData;

        bytes32 mediaId; // ID of the media Type, e.q keccak256("MOVIE"), keccak256("YOUTUBE")... Should this be platform?

        // Intermediate steps before granting, such as approval by parent, KYC... Triggered in beforeTransfer.
        address grantProcessor;
        bytes grantData;

        // Terms for revoking the license, not temporal, for example Moral Rights, Can't be Evil, etc. Useful for disputes
        address revocationTermsInterpreter;
        bytes revocationTermsData;
        address revoker;

        // Temporal terms and address that could renew the license
        LibTimeConditional.TimeConfig timeConfig;

        string termsURI;
        
    }

    mapping(uint256 => License) private _licenses;

}