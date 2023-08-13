// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { LibTimeConditional } from "../timing/LibTimeConditional.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { AccessControlledUpgradeable } from "contracts/access-control/AccessControlledUpgradeable.sol";
import { UPGRADER_ROLE } from "contracts/access-control/ProtocolRoles.sol";
import { Base64 } from 'base64-sol/base64.sol';
import { Strings } from '@openzeppelin/contracts/utils/Strings.sol';

contract LicensingModule is UUPSUpgradeable, ERC721Upgradeable, AccessControlledUpgradeable {
    using Strings for uint;
    
    event LicenseGranted (
        uint256 indexed licenseId,
        address holder,
        address ipAssetRegistry,
        uint256 ipAssetId,
        uint256 parentLicenseId,
        string scope,
        string duration,
        string rights,
        string imageURI,
        string name
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

    struct DemoTerms {
        string imageURI;
        string usage;
        string duration;
        string rights;
        string name;
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

        DemoTerms demoTerms;
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
        DemoTerms calldata demoTerms,
        string memory licenseURI
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
            demoTerms,
            licenseURI
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
        DemoTerms calldata demoTerms,
        string memory licenseURI
    ) private returns (uint256 licenseId) {
        
        licenseId = _emitLicense(
            parentLicenseId,
            mediaId,
            generalTerms,
            ownershipParams,
            demoTerms,
            licenseURI
        );

        // Not bound to a token, mint to holder
        if (ownershipParams.holder != address(0)) {
            _mint(ownershipParams.holder, licenseId);
        }
        _emitEvent(licenseId, ownershipParams, parentLicenseId, demoTerms);
        
        return licenseId;
    }

    function _emitEvent(uint256 licenseId, OwnershipParams memory ownershipParams, uint256 parentLicenseId, DemoTerms memory demoTerms) private {
        emit LicenseGranted(
            licenseId,
            ownershipParams.holder,
            address(ownershipParams.token.collection),
            ownershipParams.token.tokenId,
            parentLicenseId,
            demoTerms.usage,
            demoTerms.duration,
            demoTerms.rights,
            demoTerms.imageURI,
            demoTerms.name
        );
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
        DemoTerms memory demoTerms,
        string memory licenseURI
    ) internal returns (uint256) {
        if (ownershipParams.holder == address(0) && _isUnsetToken(ownershipParams.token)) revert("License must be bound to a token or a license holder");
        // TODO: validate all terms
        LicenseModuleStorage storage $ = _getLicenseModuleStorage();
        uint256 currentCounter = $.licenseCounter++;
        $.licenses[currentCounter] = License({
            active: true,
            parentLicenseId: parentLicenseId,
            mediaId: mediaId,
            generalTerms: generalTerms,
            licensedToken: ownershipParams.token,
            demoTerms: demoTerms,
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

    function tokenURI(uint256 tokenId_) public view override returns (string memory) {
        require(_exists(tokenId_), 'URI query for nonexistent token');
        License memory license = _getLicenseModuleStorage().licenses[tokenId_];
        string memory name = string(abi.encodePacked('Story Protocol License #', tokenId_.toString()));
        string memory description = string(abi.encodePacked('Commercial license for the Story Protocol IP Asset: ', license.demoTerms.name));
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"', name,
                            '", "description":"', description,
                            '", "image": "', license.demoTerms.imageURI,
                            '", "external_url": "', license.licenseURI,
                            '", "attributes": [{"trait_type": "usage", "value": "', license.demoTerms.usage, '"},',
                            '{"trait_type": "duration", "value": "', license.demoTerms.duration, '"},',
                            '{"trait_type": "rights", "value": "', license.demoTerms.rights, '"}]'
                            '}')
                    )
                )
            )
        );
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyRole(UPGRADER_ROLE) {}

}