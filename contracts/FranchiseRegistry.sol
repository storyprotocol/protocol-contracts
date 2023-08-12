// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IPAsset } from "./IPAsset.sol";
import { IPAssetRegistryFactory } from "./ip-assets/IPAssetRegistryFactory.sol";
import { AccessControlledUpgradeable } from "./access-control/AccessControlledUpgradeable.sol";
import { UPGRADER_ROLE } from "./access-control/ProtocolRoles.sol";
import { ZeroAddress, Unauthorized } from "./errors/General.sol";
import { IVersioned } from "./utils/IVersioned.sol";
import { IIPAssetRegistry } from "./ip-assets/IIPAssetRegistry.sol";
import { LibIPAssetId } from "./ip-assets/LibIPAssetId.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { LicensingModule } from "./modules/licensing/LicensingModule.sol";
import { LibTimeConditional } from "./modules/timing/LibTimeConditional.sol";

contract FranchiseRegistry is
    UUPSUpgradeable,
    IVersioned,
    AccessControlledUpgradeable,
    ERC721Upgradeable
{
    event FranchiseRegistered(
        address owner,
        uint256 id,
        address ipAssetRegistryForId,
        string name,
        string symbol,
        string tokenURI
    );
    error AlreadyRegistered();

    struct FranchiseCreationParams {
        string name;
        string symbol;
        string description;
        string tokenURI;
    }

    /// @custom:storage-location erc7201:story-protocol.franchise-registry.storage
    struct FranchiseStorage {
        uint256 franchiseIds;
        /// Franchise id => IPAssetRegistry address
        mapping(uint256 => address) ipAssetRegistries;
        mapping(uint256 => string) tokenURIs;
        LicensingModule licensingModule;
    }

    IPAssetRegistryFactory public immutable FACTORY;
    // keccak256(bytes.concat(bytes32(uint256(keccak256("story-protocol.franchise-registry.storage")) - 1)))
    bytes32 private constant _STORAGE_LOCATION = 0x5648324915b730d22cca7279385130ad43fd4829d795fb20e9ab398bfe537e8f;
    uint256 public constant PROTOCOL_ROOT_ID = 0;
    address public constant PROTOCOL_ROOT_ADDRESS = address(0);
    string private constant _VERSION = "0.1.0";

    constructor(address _factory) {
        if (_factory == address(0)) revert ZeroAddress();
        FACTORY = IPAssetRegistryFactory(_factory);
        _disableInitializers();
    }

    function initialize(address accessControl) public initializer {
        __UUPSUpgradeable_init();
        __AccessControlledUpgradeable_init(accessControl);
        __ERC721_init("Story Protocol", "SP");
    }

    function setLicensingModule(LicensingModule module) external{
        // TODO: set protocol role for this and check sender
        if (address(module) == address(0)) revert ZeroAddress();
        _getFranchiseStorage().licensingModule = module;
    }

    function _getFranchiseStorage() private pure returns (FranchiseStorage storage $) {
        assembly {
            $.slot := _STORAGE_LOCATION
        }
    }

    function version() external pure override returns (string memory) {
        return _VERSION;
    }

    function registerFranchise(FranchiseCreationParams calldata params) external returns (uint256, address) {
        FranchiseStorage storage $ = _getFranchiseStorage();
        uint256 nextId = ++$.franchiseIds;
        address ipAssetRegistry = FACTORY.createFranchiseIPAssets(
            nextId,
            params.name,
            params.symbol,
            params.description
        );
        $.ipAssetRegistries[nextId] = ipAssetRegistry;
        $.tokenURIs[nextId] = params.tokenURI;
        _safeMint(msg.sender, nextId);
        // TODO: set licensing restrictions per franchise, maybe grant commercial root license to the franchise NFT
        
        emit FranchiseRegistered(msg.sender, nextId, ipAssetRegistry, params.name, params.symbol, params.tokenURI);
        
        return (nextId, ipAssetRegistry);
    }

    function ipAssetRegistryForId(
        uint256 franchiseId
    ) public view returns (address) {
        FranchiseStorage storage $ = _getFranchiseStorage();
        return $.ipAssetRegistries[franchiseId];
    }

    
    /**
     * @notice checks if an address is a valid SP IPAssetRegistry.
     * @param ipAssetRegistry the address to check
     * @return true if it's a valid SP IPAssetRegistry, false otherwise
     */
    function isIpAssetRegistry(address ipAssetRegistry) external view returns(bool) {
        try IIPAssetRegistry(ipAssetRegistry).franchiseId() returns (uint256 franchiseId) {
            return ipAssetRegistryForId(franchiseId) == ipAssetRegistry;
        } catch {
            return false;
        }
    }

    // TODO create asset as derivative of another asset
    function createIPAsset(
        uint256 franchiseId,
        IPAsset sb,
        string calldata name,
        string calldata _description,
        string calldata mediaUrl
    ) external returns (uint256 ipAssetID) {
        FranchiseStorage storage $ = _getFranchiseStorage();
        address ipAssetRegistry = $.ipAssetRegistries[franchiseId];
        ipAssetID = IIPAssetRegistry(ipAssetRegistry).createIPAsset(sb, name, _description, mediaUrl, msg.sender);
        // For demo, every IPAsset has root comercial and non commercial licenses. Both can sublicense
        LicensingModule.OwnershipParams memory ownershipParams = LicensingModule.OwnershipParams({
            holder: address(0),
            token: LicensingModule.Token({
                collection: IERC721(ipAssetRegistry),
                tokenId: ipAssetID
            })
        });
        _demoGrantLicense(keccak256("FULL_COMMERCIAL_RIGHTS"), true, true, 0, ownershipParams, "");
        _demoGrantLicense(keccak256("NON_COMMERCIAL_PUBLIC_NFT_SHARE_ALIKE"), false, true, 0, ownershipParams, "");
        return ipAssetID;
    }

    function createLicense(
        uint256 franchiseId,
        uint256 ipAssetId,
        bool commercial,
        bytes32 mediaId,
        string memory licenseURI
    ) external returns (uint256) {
        FranchiseStorage storage $ = _getFranchiseStorage();
        address ipAssetRegistry = $.ipAssetRegistries[franchiseId];
        uint256 parentLicenseId = $.licensingModule.licenseIdForToken(ipAssetRegistry, ipAssetId);
        LicensingModule.OwnershipParams memory ownershipParams = LicensingModule.OwnershipParams({
            holder: msg.sender,
            token: LicensingModule.Token({
                collection: IERC721(address(0)),
                tokenId: 0
            })
        });
        return _demoGrantLicense(mediaId, commercial, false, parentLicenseId, ownershipParams, licenseURI);
    }

    function _demoGrantLicense(
        bytes32 mediaId,
        bool commercial,
        bool canSublicense,
        uint256 parentLicenseId,
        LicensingModule.OwnershipParams memory ownershipParamns,
        string memory licenseUri
    ) private returns (uint256) {
        FranchiseStorage storage $ = _getFranchiseStorage();
        return $.licensingModule.grantLicense(
            msg.sender,
            parentLicenseId,
            mediaId,
            LicensingModule.GeneralTerms({
                exclusive: false,
                canSublicense: canSublicense,
                commercial: commercial
            }),
            ownershipParamns,
            LicensingModule.PaymentTerms({
                interpreter: address(0),
                data: ""
            }),
            LicensingModule.GrantingTerms({
                processor: address(0),
                data: ""
            }),
            LibTimeConditional.TimeConfig({
                maxTTL: 0,
                minTTL: 0,
                renewable: false,
                renewer: address(0),
                endTime: 0
            }),
            licenseUri, // License URI ignored for non commercial
            address(0) // No revoker for demo
        );
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        FranchiseStorage storage $ = _getFranchiseStorage();
        return $.tokenURIs[tokenId];
    } 

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyRole(UPGRADER_ROLE) {}

}