// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { IIPOrg } from "contracts/interfaces/ip-org/IIPOrg.sol";
import { IPAsset } from "contracts/lib/IPAsset.sol";
import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { IERC165Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import { MulticallUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import { IPAssetRegistry } from "contracts/IPAssetRegistry.sol";
import { Errors } from "contracts/lib/Errors.sol";

/// @notice IP Asset Organization
contract IPOrg is
    ERC721Upgradeable,
    MulticallUpgradeable,
    OwnableUpgradeable
{

    /// @custom:storage-location erc7201:story-protocol.ip-asset-org.storage
    // TODO: Refactor IP asset types to be specified through the IP Asset Registry or one of its modules.
    struct IPOrgStorage {

    }

    IPAssetRegistry public REGISTRY;

    // keccak256(bytes.concat(bytes32(uint256(keccak256("story-protocol.ip-org-registry.storage")) - 1)))
    bytes32 private constant _STORAGE_LOCATION = 0x1a0b8fa444ff575656111a4368b8e6a743b70cbf31ffb9ee2c7afe1983f0e378;
    string private constant _VERSION = "0.1.0";

    // TODO(ramarti): Refactor to configure IP Asset types via registry modules.
    uint256 private constant _ROOT_IP_ASSET = 0;

    /// @notice Returns the current version of the IP asset org contract.
    function version() external pure virtual returns (string memory) {
        return _VERSION;
    }

    function initialize(IPAsset.InitIPOrgParams memory params_) public initializer {

        // TODO(ramarti) Decouple IPOrg from the RightsManager and make sure to move `__ERC721_init` here.
        __ERC721_init(params_.name, params_.symbol);

        __Multicall_init();
        __Ownable_init();
        // TODO: Weird bug does not allow OZ to specify owner in init...
        _transferOwnership(params_.owner);

        if (params_.registry == address(0)) revert Errors.ZeroAddress();
        REGISTRY = IPAssetRegistry(params_.registry);
    }


    /// @notice Retrieves the token URI for an IP Asset within the IP Asset Org.
    /// @param tokenId_ The id of the IP Asset within the IP Asset Org.
    function tokenURI(
        uint256 tokenId_
    ) public view override returns (string memory) {
        // TODO: should this reference the license too?
        return "TODO";
    }

    /// @dev Gets the storage associated with the IPOrg contract.
    function _getIPOrgStorage()
        private
        pure
        returns (IPOrgStorage storage $)
    {
        assembly {
            $.slot := _STORAGE_LOCATION
        }
    }
}
