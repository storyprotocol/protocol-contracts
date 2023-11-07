// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { IPAsset } from "contracts/lib/IPAsset.sol";
import { IPAssetOrgDataManager } from "./storage/IPAssetOrgDataManager.sol";
import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { MulticallUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import { IPAssetRegistry } from "contracts/IPAssetRegistry.sol";
import { Errors } from "contracts/lib/Errors.sol";

/// @notice IP Asset Organization
contract IPAssetOrg is
    ERC721Upgradeable,
    IPAssetOrgDataManager,
    MulticallUpgradeable,
    OwnableUpgradeable
{
    /// @custom:storage-location erc7201:story-protocol.ip-asset-org.storage
    // TODO: Refactor IP asset types to be specified through the IP Asset Registry or one of its modules.
    struct IPAssetOrgStorage {
        /// @dev ipAssetId => id counter
        mapping(IPAsset.IPAssetType => uint256) idsByType;
    }

    IPAssetRegistry public REGISTRY;

    // keccak256(bytes.concat(bytes32(uint256(keccak256("story-protocol.ip-assets-registry.storage")) - 1)))
    bytes32 private constant _STORAGE_LOCATION =
        0x1a0b8fa444ff575656111a4368b8e6a743b70cbf31ffb9ee2c7afe1983f0e378;

    string private constant _VERSION = "0.1.0";

    // TODO(ramarti): Refactor to configure IP Asset types via registry modules.
    uint256 private constant _ROOT_IP_ASSET = 0;

    /// @notice Returns the current version of the IP asset org contract.
    function version() external pure virtual returns (string memory) {
        return _VERSION;
    }

    function initialize(
        IPAsset.InitIPAssetOrgParams memory params_
    ) public initializer {
        __Multicall_init();
        __Ownable_init();
        __ERC721_init(params_.name, params_.symbol);
        // TODO: Weird bug does not allow OZ to specify owner in init...
        _transferOwnership(params_.owner);

        if (params_.registry == address(0)) revert Errors.ZeroAddress();
        REGISTRY = IPAssetRegistry(params_.registry);
    }

    /// Creates a new IPAsset, and assigns licenses (rights) to it, according to the IPAssetOrg
    /// config in LicensingModule.
    /// A Non commercial license is always assigned, and if the IPAsset is a root IPAsset,
    /// a commercial license may also be assigned.
    /// @dev reverts if LicensingModule is not configured for the IPAssetOrg.
    /// @param params_ The parameters used for IP Asset creation.
    /// @return the created IP Asset id (and IP Asset org id).
    /// TODO(ramarti): Refactor licensing configuration to use registry asset ids instead of ip asset org ids.
    /// TODO(leeren): Deprecate returning of internal IP Asset org id once existing dependencies to it are removed.
    function createIpAsset(
        IPAsset.CreateIpAssetParams calldata params_
    ) public returns (uint256, uint256) {
        if (params_.ipAssetType == IPAsset.IPAssetType.UNDEFINED) {
            revert Errors.IPAsset_InvalidType(IPAsset.IPAssetType.UNDEFINED);
        }

        IPAsset.RegisterIpAssetParams memory registrationParams = IPAsset
            .RegisterIpAssetParams({
                name: params_.name,
                ipAssetType: 0, // TODO(ramarti): Replace with valid licensing type.
                owner: params_.to,
                ipOrg: address(this),
                hash: "",
                url: "",
                data: ""
            });

        // TODO: Add module and other relevant configuration for registration.
        uint256 ipAssetId = REGISTRY.register(registrationParams);
        uint256 ipAssetOrgId = _mintBlock(params_.to, params_.ipAssetType);
        _writeIPAsset(
            ipAssetId,
            ipAssetOrgId,
            params_.name,
            params_.description,
            params_.mediaUrl
        );

        return (ipAssetId, ipAssetOrgId);
    }

    /// @notice Retrieves the token URI for an IP Asset within the IP Asset Org.
    /// @param tokenId_ The id of the IP Asset within the IP Asset Org.
    function tokenURI(
        uint256 tokenId_
    ) public view override returns (string memory) {
        // TODO: should this reference the license too?
        return readIPAsset(tokenId_).mediaUrl;
    }

    /// @notice Mints a new IP asset localized for the IP Asset Org.
    /// @param to_ Address of the owner of the IP Asset.
    /// @param ipAssetType_ Type of the IP Asset.
    /// TODO: Deprecate use of IP Asset types in the IP Asset Org contract.
    function _mintBlock(
        address to_,
        IPAsset.IPAssetType ipAssetType_
    ) private returns (uint256) {
        uint256 nextId = currentIdFor(ipAssetType_) + 1;
        if (nextId > IPAsset._lastId(ipAssetType_)) {
            revert Errors.IPAssetOrg_IdOverBounds();
        }
        IPAssetOrgStorage storage $ = _getIPAssetOrgStorage();
        $.idsByType[ipAssetType_] = nextId;
        _safeMint(to_, nextId);
        return nextId;
    }

    /// @notice Gets the next id that a newly minted IP Asset corresponds to.
    /// @param ipAssetType_ The type of the IP Asset being queried.
    function currentIdFor(
        IPAsset.IPAssetType ipAssetType_
    ) public view returns (uint256) {
        IPAssetOrgStorage storage $ = _getIPAssetOrgStorage();
        uint256 currentId = $.idsByType[ipAssetType_];
        if (currentId == 0) {
            return IPAsset._zeroId(ipAssetType_);
        } else {
            return currentId;
        }
    }

    /// @dev Gets the storage associated with the IPAssetOrg contract.
    function _getIPAssetOrgStorage()
        private
        pure
        returns (IPAssetOrgStorage storage $)
    {
        assembly {
            $.slot := _STORAGE_LOCATION
        }
    }
}
