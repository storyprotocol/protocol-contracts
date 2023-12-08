// SPDX-License-Identifier: UNLICENSED
// See https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.19;

import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import { AccessControlledUpgradeable } from "contracts/access-control/AccessControlledUpgradeable.sol";
import { ModuleRegistry } from "contracts/modules/ModuleRegistry.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { Registration } from "contracts/lib/modules/Registration.sol";
import { IIPOrgController } from "contracts/interfaces/ip-org/IIPOrgController.sol";
import { IIPOrg } from "contracts/interfaces/ip-org/IIPOrg.sol";
import { IPOrg } from "contracts/ip-org/IPOrg.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { REGISTRATION_MODULE } from "contracts/lib/modules/Module.sol";

/// @title IP Org Controller Contract
/// @notice The IP Org Controller is the protocol-wide factory contract for creating
///         and tracking IP Orgs. On top of this, it acts as the ownership controller
///         for IP Orgs, allowing orgs to transfer ownership through a 2-step process.
contract IPOrgController is UUPSUpgradeable, AccessControlledUpgradeable, IIPOrgController {
    /// @notice Tracks ownership and registration of IPOrgs.
    struct IPOrgRecord {
        bool registered;
        address owner;
        address pendingOwner;
    }

    /// @custom:storage-location erc7201:story-protocol.ip-org-factory.storage
    struct IPOrgControllerStorage {
        /// @dev Tracks registered IP Orgs through records of ownership.
        mapping(address => IPOrgRecord) ipOrgs;
        /// @dev Tracks owner of the IP Org Controller.
        address owner;
    }

    bytes32 private constant _STORAGE_LOCATION =
        bytes32(uint256(keccak256("story-protocol.ip-org-factory.storage")) - 1);

    /// @notice The IP asset module registry.
    address public immutable MODULE_REGISTRY;

    /// @notice The IP Org implementation address.
    address public ipOrgImpl;

    /// @notice Creates the IP Org Controller contract.
    /// @param moduleRegistry_ Address of the IP asset module registry.
    constructor(address moduleRegistry_) {
        MODULE_REGISTRY = moduleRegistry_;
    }

    /// @notice Initializes the IP Org Controller
    /// @param accessControl_ Address of the contract responsible for access control.
    /// TODO(leeren): Deprecate this function in favor of an immutable factory.
    function initialize(address accessControl_) public initializer {
        ipOrgImpl = address(new IPOrg(address(this), MODULE_REGISTRY));
        __UUPSUpgradeable_init();
        __AccessControlledUpgradeable_init(accessControl_);
    }

    /// @notice Retrieves the current owner of an IP Org.
    /// @param ipOrg_ The address of the IP Org being queried.
    function ownerOf(address ipOrg_) external view returns (address) {
        IPOrgRecord storage record = _ipOrgRecord(ipOrg_);
        return record.owner;
    }

    /// @notice Returns whether an IP Org has been officially registered.
    /// @param ipOrg_ The address of the IP Org being queried.
    function isIpOrg(address ipOrg_) external view returns (bool) {
        IPOrgControllerStorage storage $ = _getIpOrgControllerStorage();
        return $.ipOrgs[ipOrg_].registered;
    }

    /// @notice Retrieves the pending owner of an IP Org.
    /// @dev A zero return address implies no ownership transfer is in process.
    /// @param ipOrg_ The address of the IP Org being queried.
    function pendingOwnerOf(address ipOrg_) external view returns (address pendingOwner) {
        IPOrgRecord storage record = _ipOrgRecord(ipOrg_);
        return record.pendingOwner;
    }

    /// @notice Initiates transfer of ownership for an IP Org.
    /// @param ipOrg_ The address of the IP Org transferring ownership.
    /// @param newOwner_ The address of the new IP Org owner.
    function transferOwner(address ipOrg_, address newOwner_) external {
        IPOrgRecord storage record = _ipOrgRecord(ipOrg_);

        // Ensure the current IP Org owner is initiating the transfer.
        if (record.owner != msg.sender) {
            revert Errors.IPOrgController_InvalidIPOrgOwner();
        }

        // Ensure the proposed new owner is not the zero address.
        if (newOwner_ == address(0)) {
            revert Errors.IPOrgController_InvalidNewIPOrgOwner();
        }

        record.pendingOwner = newOwner_;
        emit IPOrgPendingOwnerSet(ipOrg_, newOwner_);
    }

    /// @notice Cancels the transferring of ownership of an IP Org.
    /// @param ipOrg_ The address of the IP Org transferring ownership.
    function cancelOwnerTransfer(address ipOrg_) external {
        IPOrgRecord storage record = _ipOrgRecord(ipOrg_);

        // Ensure the current IP Org owner is canceling the transfer.
        if (record.owner != msg.sender) {
            revert Errors.IPOrgController_InvalidIPOrgOwner();
        }

        // Ensure an ongoing ownership transfer has actually initiated.
        if (record.pendingOwner == address(0)) {
            revert Errors.IPOrgController_OwnerTransferUninitialized();
        }

        delete record.pendingOwner;
        emit IPOrgPendingOwnerSet(ipOrg_, address(0));
    }

    /// @notice Accepts the transferring of ownership of an IP Org.
    /// @param ipOrg_ The address of the IP Org being transferred.
    function acceptOwnerTransfer(address ipOrg_) external {
        IPOrgRecord storage record = _ipOrgRecord(ipOrg_);

        // Ensure the pending IP Org owner is accepting the ownership transfer.
        if (record.pendingOwner != msg.sender) {
            revert Errors.IPOrgController_InvalidIPOrgOwner();
        }

        // Reset the pending owner.
        address prevOwner = record.owner;
        delete record.pendingOwner;
        record.owner = msg.sender;

        emit IPOrgPendingOwnerSet(ipOrg_, address(0));
        emit IPOrgTransferred(ipOrg_, prevOwner, msg.sender);
    }

    /// @notice Registers a new IP Org.
    /// @param owner_ The address of the IP Org to be registered.
    /// @param name_ The name to associated with the new IP Org.
    /// @param symbol_ The symbol to associate with the new IP Org.
    /// TODO: Add module configurations to the IP Org registration process.
    /// TODO: Add authorization for IP Org registration.
    function registerIpOrg(
        address owner_,
        string calldata name_,
        string calldata symbol_,
        string[] calldata ipAssetTypes_
    ) public returns (address ipOrg_) {
        // Check that the owner is a non-zero address.
        if (owner_ == address(0)) {
            revert Errors.ZeroAddress();
        }

        ipOrg_ = Clones.clone(ipOrgImpl);
        IPOrg(ipOrg_).initialize(name_, symbol_);

        // Set the registration status of the IP Asset Org to be true.
        IPOrgControllerStorage storage $ = _getIpOrgControllerStorage();
        $.ipOrgs[ipOrg_] = IPOrgRecord({ registered: true, owner: owner_, pendingOwner: address(0) });

        bytes memory encodedParams = abi.encode(Registration.SET_IP_ORG_ASSET_TYPES, abi.encode(ipAssetTypes_));
        ModuleRegistry(MODULE_REGISTRY).configure(IIPOrg(ipOrg_), address(this), REGISTRATION_MODULE, encodedParams);

        emit IPOrgRegistered(owner_, ipOrg_, name_, symbol_, ipAssetTypes_);
    }

    /// @dev Gets the ownership record of an IP Org.
    /// @param ipOrg_ The address of the IP Org being queried.
    function _ipOrgRecord(address ipOrg_) internal view returns (IPOrgRecord storage record) {
        IPOrgControllerStorage storage $ = _getIpOrgControllerStorage();
        record = $.ipOrgs[ipOrg_];
        if (!$.ipOrgs[ipOrg_].registered) {
            revert Errors.IPOrgController_IPOrgNonExistent();
        }
    }

    /// @dev Authorizes upgrade to a new contract address via UUPS.
    function _authorizeUpgrade(address) internal virtual override onlyRole(AccessControl.UPGRADER_ROLE) {}

    /// @dev Retrieves the ERC-1967 storage slot for the IP Org Controller.
    function _getIpOrgControllerStorage() private pure returns (IPOrgControllerStorage storage $) {
        bytes32 storageLocation = _STORAGE_LOCATION;
        assembly {
            $.slot := storageLocation
        }
    }
}
