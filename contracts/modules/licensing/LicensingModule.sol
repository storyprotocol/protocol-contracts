// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { LibTimeConditional } from "../timing/LibTimeConditional.sol";

contract LicensingModule is ERC721 {

    event LicenseGranted (
        uint256 indexed licenseId,
        address holder,
        address token,
        uint256 tokenId,
        uint256 parentLicenseId
    );

    struct Token {
        IERC721 collection;
        uint256 tokenId;
    }

    struct GeneralTerms {
        bool exclusive;// Ignored now, TODO
        bool canSublicense; // TODO: consider sublicensing limitations (i.e can only sublicense for media X, etc.)
        bool commercial;
    }

    struct PaymentTerms {
        address interpreter;
        bytes data;
    }

    struct GrantingTerms {
        address processor;
        bytes data;
    }

    struct OwnershipParams {
        address holder;
        Token token;
    }

    struct License {
        bool active;
        uint256 parentLicenseId;
        bytes32 mediaId; // ID of the media Type, e.q keccak256("MOVIE"), keccak256("MOVIE"), keccak256("MERCHANDISE")... Should this be "platform"?
        GeneralTerms generalTerms;

        // If licensed token is set, the license is bound to a token, so ownerOf must return 0, and the license is not transferrable
        Token licensedToken;

        // Contract defining the payment terms, royalties, milestones, etc.
        // The interpreter does not necessarily enforce the terms.
        PaymentTerms paymentTerms;

        // Intermediate steps before granting, such as approval by parent, KYC, revenue splits are set, time limits for transfer, security stuff...
        // Triggered in beforeTransfer.
        GrantingTerms grantingTerms;
        address revoker;

        // Temporal terms and address that could renew the license
        LibTimeConditional.TimeConfig durationTerms;
        string licenseURI;
    }

    mapping(uint256 => License) private _licenses;
    uint256 private _licenseCounter;

    // TODO
    mapping(address => bool) _bannedMarketPlaces;
    // Each franchise can choose to restrict stuff, like allowed license templates, the holder of root commercial licenses can only be
    // the franchise owner and external PFP owners, etc.
    mapping(uint256 => bytes) _franchiseRestrictions;
    
    string public nonCommercialLicenseURI;
    address immutable public FRANCHISE_REGISTRY;

    modifier onlyFranchiseRegistry() {
        // TODO: extract to FranchiseRegistryControlled.sol
        if (msg.sender != FRANCHISE_REGISTRY) revert("Sender is not the franchise registry");
        _;
    }

    constructor(string memory name, string memory symbol, string memory _nonCommercialLicenseURI, address franchiseRegistry) ERC721(name, symbol) {
        nonCommercialLicenseURI = _nonCommercialLicenseURI;
        if (franchiseRegistry == address(0)) revert("Franchise registry cannot be zero address");
        FRANCHISE_REGISTRY = franchiseRegistry;
    }

    function isLicenseActive(uint256 licenseId) public view virtual returns (bool) {
        // TODO: limit to the tree depth
        // TODO: check time limits 
        if (licenseId == 0) return false;
        while (licenseId != 0) {
          if (!_licenses[licenseId].active) return false;
          licenseId = _licenses[licenseId].parentLicenseId;
        }
        return true;
    }

    function grantLicense(
        address licensor,
        uint256 parentLicenseId,
        bytes32 mediaId,
        GeneralTerms memory generalTerms,
        OwnershipParams calldata ownershipParams,
        PaymentTerms memory paymentTerms,
        GrantingTerms memory grantingTerms,
        LibTimeConditional.TimeConfig memory durationTerms,
        string memory licenseURI,
        address revoker
    ) public onlyFranchiseRegistry returns (uint256) {
        if (parentLicenseId != 0) {
            License memory parentLicense = _licenses[parentLicenseId];
            _verifySublicense(parentLicenseId, licensor, parentLicense, generalTerms);
            licenseURI = parentLicense.licenseURI;
        } else {
            if (!generalTerms.commercial) {
                licenseURI = nonCommercialLicenseURI;
            }
        }
        
        // TODO: check other terms
        uint256 licenseId;
        {
            licenseId = _emitLicense(
                parentLicenseId,
                mediaId,
                generalTerms,
                ownershipParams,
                paymentTerms,
                grantingTerms,
                durationTerms,
                licenseURI,
                revoker
            );
            // Not bound to a token, mint to holder
            if (ownershipParams.holder != address(0)) {
                _mint(ownershipParams.holder, licenseId);
            }
            emit LicenseGranted(
                licenseId,
                ownershipParams.holder,
                address(ownershipParams.token.collection),
                ownershipParams.token.tokenId,
                parentLicenseId
            );
        }
        return licenseId;
    }


    function _verifySublicense(uint256 parentLicenseId, address licensor, License memory parentLicense, GeneralTerms memory generalTerms) private view {
        if (ownerOf(parentLicenseId) != licensor) revert("Sender is not the owner of the parent license");
        if (!parentLicense.active) revert("Parent license is not active");
        if (!parentLicense.generalTerms.canSublicense) revert("Parent license cannot be sublicensed");
        if (parentLicense.generalTerms.commercial != generalTerms.commercial) revert("Commercial terms must be the same as parent license");
    }

    function _isUnsetToken(Token memory token) private pure returns (bool) {
        return address(token.collection) == address(0);
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        // TODO: This should work with ERC6665 or similar, this is only for demo
        Token memory token = _licenses[tokenId].licensedToken;
        if (address(token.collection) != address(0)) {
            return token.collection.ownerOf(token.tokenId);
        }
        return super.ownerOf(tokenId);
    }

    function _emitLicense(
        uint256 parentLicenseId,
        bytes32 mediaId,
        GeneralTerms memory generalTerms,
        OwnershipParams memory ownershipParams,
        PaymentTerms memory paymentTerms,
        GrantingTerms memory grantingTerms,
        LibTimeConditional.TimeConfig memory durationTerms,
        string memory licenseURI,
        address revoker
    ) internal returns (uint256) {
        if (ownershipParams.holder == address(0) && _isUnsetToken(ownershipParams.token)) revert("License must be bound to a token or a license holder");
        if (ownershipParams.holder != address(0) && !_isUnsetToken(ownershipParams.token)) revert("License cannot be bound to a token and a license holder at the same time");
        // TODO: validate all terms
        _licenseCounter++;
        _licenses[_licenseCounter] = License({
            active: true,
            parentLicenseId: parentLicenseId,
            mediaId: mediaId,
            generalTerms: generalTerms,
            licensedToken: ownershipParams.token,
            paymentTerms: paymentTerms,
            grantingTerms: grantingTerms,
            revoker: revoker,
            durationTerms: durationTerms,
            licenseURI: licenseURI
        });
        return _licenseCounter;
    }

    function getLicense(uint256 licenseId) public view returns (License memory, address holder) {
        return (_licenses[licenseId], ownerOf(licenseId));
    }


    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        // TODO: check granting terms, banned marketplaces, etc.
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }
}