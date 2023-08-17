// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { LibTimeConditional } from "../timing/LibTimeConditional.sol";
import { UPGRADER_ROLE } from "contracts/access-control/ProtocolRoles.sol";
import { IERC5218 } from "./IERC5218.sol";
import { LicenseRegistry } from "./LicenseRegistry.sol";
import { NonExistentID, Unauthorized, ZeroAddress } from "contracts/errors/General.sol";
import { IERC165Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

abstract contract RightsManager is
    ERC721Upgradeable,
    IERC5218
{
    error NotOwnerOfParentLicense();
    error InactiveLicense();
    error InactiveParentLicense();
    error CannotSublicense();
    error CommercialTermsMismatch();
    error SenderNotRevoker();
    error NotSublicense();
    error AlreadyHasRootLicense();

    struct License {
        bool active;
        bool canSublicense;
        bool commercial;
        uint256 parentLicenseId;
        uint256 tokenId;
        address revoker;
        string uri; // NOTE: should we merge this with IPAssetRegistry tokenURI for Licenses who are rights?
    }

    struct LicenseModuleStorage {
        mapping(uint256 => License) licenses;
        // keccack256(commercial, tokenId) => licenseId
        mapping(bytes32 => uint256) licenseForTokenId;
        uint256 licenseCounter;
        string nonCommercialLicenseURI;
    }

    // keccak256(bytes.concat(bytes32(uint256(keccak256("story-protocol.license-module.storage")) - 1)))
    bytes32 private constant _STORAGE_LOCATION =
        0x778e3a21329d920b45eecf00e356693a1888f1ae24d67d398ab1f17457bcfabd;
    uint256 private constant _UNSET_LICENSE_ID = 0;
    LicenseRegistry public immutable LICENSE_REGISTRY;


    constructor() {
        LICENSE_REGISTRY = new LicenseRegistry(address(this), "Licenses", "SPLC");
    }

    function __RightsManager_init(
        string calldata _nonCommercialLicenseURI,
        string calldata name,
        string calldata symbol
    ) public initializer {
        __ERC721_init(name, symbol);
        _getLicenseModuleStorage()
            .nonCommercialLicenseURI = _nonCommercialLicenseURI;
    }

    function setNonCommercialLicenseURI(
        string calldata _nonCommercialLicenseURI
    ) external virtual;

    function _setNonCommercialLicenseURI(
        string calldata _nonCommercialLicenseURI
    ) internal {
        _getLicenseModuleStorage()
            .nonCommercialLicenseURI = _nonCommercialLicenseURI;
    }

    function _getLicenseModuleStorage()
        private
        pure
        returns (LicenseModuleStorage storage $)
    {
        assembly {
            $.slot := _STORAGE_LOCATION
        }
    }

    function getNonCommercialLicenseURI() public view returns (string memory) {
        return _getLicenseModuleStorage().nonCommercialLicenseURI;
    }

    function isLicenseActive(
        uint256 licenseId
    ) public view virtual returns (bool) {
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

    function _verifySublicense(
        uint256 parentLicenseId,
        address licensor,
        bool commercial,
        License memory parentLicense
    ) private view {
        if (ownerOf(parentLicenseId) != licensor) revert NotOwnerOfParentLicense();
        if (!parentLicense.active) revert InactiveParentLicense();
        if (!parentLicense.canSublicense) revert CannotSublicense();
        if (parentLicense.commercial != commercial) revert CommercialTermsMismatch();
    }

    function getLicense(
        uint256 licenseId
    ) public view returns (License memory, address holder) {
        return (
            _getLicenseModuleStorage().licenses[licenseId],
            getLicenseHolder(licenseId)
        );
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

    function getLicenseTokenId(
        uint256 _licenseId
    ) external view override returns (uint256) {
        return _getLicenseModuleStorage().licenses[_licenseId].tokenId;
    }

    function getParentLicenseId(
        uint256 _licenseId
    ) external view override returns (uint256) {
        return _getLicenseModuleStorage().licenses[_licenseId].parentLicenseId;
    }

    function getLicenseHolder(
        uint256 _licenseId
    ) public view override returns (address) {
        License memory license = _getLicenseModuleStorage().licenses[
            _licenseId
        ];
        if (license.parentLicenseId == _UNSET_LICENSE_ID) {
            return ownerOf(_licenseId);
        } else {
            return LICENSE_REGISTRY.ownerOf(_licenseId);
        }
    }

    function getLicenseURI(
        uint256 _licenseId
    ) external view override returns (string memory) {
        return _getLicenseModuleStorage().licenses[_licenseId].uri;
    }

    function getLicenseRevoker(
        uint256 _licenseId
    ) external view override returns (address) {
        return _getLicenseModuleStorage().licenses[_licenseId].revoker;
    }

    function getLicenseIdByTokenId(
        uint256 _tokenId,
        bool _commercial
    ) external view override returns (uint256) {
        return
            _getLicenseModuleStorage().licenseForTokenId[
                keccak256(abi.encode(_commercial, _tokenId))
            ];
    }

    function isRootLicense(
        uint256 licenseId
    ) public view returns (bool) {
        return _getLicenseModuleStorage().licenses[licenseId].parentLicenseId == _UNSET_LICENSE_ID;
    }

    function createLicense(
        uint256 _tokenId,
        uint256 _parentLicenseId,
        address _licenseHolder, // NOTE: MODIFIED ERC-5218, we should ignore this
        string memory _uri,
        address _revoker,
        bool _commercial,
        bool _canSublicense
    ) public override returns (uint256) {
        if (_parentLicenseId == _UNSET_LICENSE_ID && msg.sender != address(this)) {
            // Root licenses aka rights can only be minted by IPAssetRegistry
            // TODO: check how to allow the Franchise NFT to have root commercial license
            revert Unauthorized();
        }
        if (!_commercial) {
            _uri = getNonCommercialLicenseURI();
        }
        return _createLicense(
            _tokenId,
            _parentLicenseId,
            _licenseHolder,
            _uri,
            _revoker,
            _commercial,
            _canSublicense
        );
    }

    function _createLicense(
        uint256 tokenId,
        uint256 parentLicenseId,
        address licenseHolder,
        string memory uri,
        address revoker,
        bool commercial,
        bool canSublicense
    ) internal returns (uint256) {
        LicenseModuleStorage storage $ = _getLicenseModuleStorage();
        if (!_exists(tokenId)) {
            revert NonExistentID(tokenId);
        }
        if ($.licenseForTokenId[
            keccak256(abi.encode(commercial, tokenId))
        ] != _UNSET_LICENSE_ID) {
            revert AlreadyHasRootLicense();
        }
        if (parentLicenseId != _UNSET_LICENSE_ID) {
            License memory parentLicense = $.licenses[parentLicenseId];
            _verifySublicense(parentLicenseId, licenseHolder, commercial, parentLicense);
        }
        uint256 licenseId = ++$.licenseCounter;
        $.licenses[licenseId] = License({
            active: true,
            canSublicense: canSublicense,
            commercial: commercial,
            parentLicenseId: parentLicenseId,
            tokenId: tokenId,
            revoker: revoker,
            uri: uri
        });
        $.licenseForTokenId[
            keccak256(abi.encode(commercial, tokenId))
        ] = licenseId;
        emit CreateLicense(
            licenseId,
            tokenId,
            parentLicenseId,
            licenseHolder,
            uri,
            revoker
        );
        _updateLicenseHolder(licenseId, licenseHolder);
        return licenseId;
    }

    function revokeLicense(uint256 _licenseId) external override {
        if (!_exists(_licenseId)) revert NonExistentID(_licenseId);
        LicenseModuleStorage storage $ = _getLicenseModuleStorage();
        License storage license = $.licenses[_licenseId];
        if (msg.sender != license.revoker) revert SenderNotRevoker();
        license.active = false;
        emit RevokeLicense(_licenseId);
    }

    function _updateLicenseHolder(
        uint256 licenseId,
        address licenseHolder
    ) internal virtual {
        emit TransferLicense(licenseId, licenseHolder);
    }

    function transferSublicense(
        uint256 licenseId,
        address licenseHolder
    ) public virtual override(IERC5218) {
        if (msg.sender != address(LICENSE_REGISTRY)) revert Unauthorized();
        if (!isLicenseActive(licenseId)) revert InactiveLicense();
        if (_getLicenseModuleStorage().licenses[licenseId].parentLicenseId == 0)
            revert CannotSublicense();
        _updateLicenseHolder(licenseId, licenseHolder);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC5218).interfaceId ||
            super.supportsInterface(interfaceId);
    }

}