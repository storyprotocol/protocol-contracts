// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { LibTimeConditional } from "../timing/LibTimeConditional.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { AccessControlledUpgradeable } from "contracts/access-control/AccessControlledUpgradeable.sol";
import { UPGRADER_ROLE } from "contracts/access-control/ProtocolRoles.sol";

contract LicensingModule is UUPSUpgradeable, ERC721Upgradeable, AccessControlledUpgradeable {

    event LicenseGranted (
        uint256 indexed licenseId,
        address holder,
        address ipAssetRegistry,
        uint256 ipAssetId,
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
        // TODO: tokenbound license config (share alike, ledger authoritative...)
    }

    struct LicenseModuleStorage {
        mapping(uint256 => License) licenses;
        uint256 licenseCounter;
        // TODO
        mapping(address => bool) bannedMarketPlaces;
        // Each franchise can choose to restrict stuff, like allowed license templates, the holder of root commercial licenses can only be
        // the franchise owner and external PFP owners, etc.
        mapping(uint256 => bytes) franchiseRestrictions;
        // TODO: Remove this
        mapping(address => mapping(uint256 => mapping(bool => uint256))) demoTokenToLicense;
        string nonCommercialLicenseURI;
    }

    // keccak256(bytes.concat(bytes32(uint256(keccak256("story-protocol.license-module.storage")) - 1)))
    bytes32 private constant _STORAGE_LOCATION = 0x778e3a21329d920b45eecf00e356693a1888f1ae24d67d398ab1f17457bcfabd;
    
    address immutable public FRANCHISE_REGISTRY;

    modifier onlyFranchiseRegistry() {
        // TODO: extract to FranchiseRegistryControlled.sol
        if (msg.sender != FRANCHISE_REGISTRY) revert("Sender is not the franchise registry");
        _;
    }

    constructor(address franchiseRegistry) {
        if (franchiseRegistry == address(0)) revert("Franchise registry cannot be zero address");
        FRANCHISE_REGISTRY = franchiseRegistry;
    }

    function initialize(string calldata _nonCommercialLicenseURI, address accessControl) public initializer {
        __UUPSUpgradeable_init();
        __AccessControlledUpgradeable_init(accessControl);
        __ERC721_init("Story Protocol License", "SPL");
        _getLicenseModuleStorage().nonCommercialLicenseURI = _nonCommercialLicenseURI;
    }

    function _getLicenseModuleStorage() private pure returns (LicenseModuleStorage storage $) {
        assembly {
            $.slot := _STORAGE_LOCATION
        }
    }

    function getNonCommercialLicenseURI() public view returns (string memory) {
        return _getLicenseModuleStorage().nonCommercialLicenseURI;
    }

    function isLicenseActive(uint256 licenseId) public view virtual returns (bool) {
        // TODO: limit to the tree depth
        // TODO: check time limits 
        if (licenseId == 0) return false;
        while (licenseId != 0) {
            LicenseModuleStorage storage $ = _getLicenseModuleStorage();
            License memory license = $.licenses[licenseId];
            if (!license.active) return false;
            licenseId = license.parentLicenseId;
        }
        return true;
    }

    function grantLicense(
        address licensor,
        uint256 parentLicenseId,
        bytes32 mediaId,
        GeneralTerms calldata generalTerms,
        OwnershipParams calldata ownershipParams,
        PaymentTerms calldata paymentTerms,
        GrantingTerms calldata grantingTerms,
        LibTimeConditional.TimeConfig calldata durationTerms,
        string memory licenseURI,
        address revoker
    ) public onlyFranchiseRegistry returns (uint256) {
        LicenseModuleStorage storage $ = _getLicenseModuleStorage();
        if (parentLicenseId != 0) {
            License memory parentLicense = $.licenses[parentLicenseId];
            _verifySublicense(parentLicenseId, licensor, parentLicense, generalTerms);
            licenseURI = parentLicense.licenseURI;
        } else {
            if (!generalTerms.commercial) {
                licenseURI = $.nonCommercialLicenseURI;
            }
        }
        
        // TODO: check other terms
        uint256 licenseId = _emitLicenseAndEvent(
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
        
        // TODO: remove this, only for demo
        $.demoTokenToLicense[address(ownershipParams.token.collection)][ownershipParams.token.tokenId][generalTerms.commercial] = licenseId;
        return licenseId;
    }

    function _emitLicenseAndEvent(
        uint256 parentLicenseId,
        bytes32 mediaId,
        GeneralTerms calldata generalTerms,
        OwnershipParams calldata ownershipParams,
        PaymentTerms calldata paymentTerms,
        GrantingTerms calldata grantingTerms,
        LibTimeConditional.TimeConfig calldata durationTerms,
        string memory licenseURI,
        address revoker
    ) private returns (uint256 licenseId) {
        
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
        Token memory token = _getLicenseModuleStorage().licenses[tokenId].licensedToken;
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
        LicenseModuleStorage storage $ = _getLicenseModuleStorage();
        uint256 currentCounter = $.licenseCounter++;
        $.licenses[currentCounter] = License({
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
        return currentCounter;
    }

    function licenseIdForToken(address collection, uint256 tokenId, bool commercial) public view returns (uint256) {
        return _getLicenseModuleStorage().demoTokenToLicense[collection][tokenId][commercial];
    }

    function getLicense(uint256 licenseId) public view returns (License memory, address holder) {
        return (_getLicenseModuleStorage().licenses[licenseId], ownerOf(licenseId));
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

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyRole(UPGRADER_ROLE) {}
}