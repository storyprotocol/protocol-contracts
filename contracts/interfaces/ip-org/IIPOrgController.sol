// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IVersioned } from "../utils/IVersioned.sol";
import { IPOrgParams } from "contracts/lib/IPOrgParams.sol";

/// @notice IP Org Controller Interface
interface IIPOrgController {

    /// @notice Emits when a new IP Org is registered.
    /// @param owner_ The address of the IP Org owner.
    /// @param ipAssetOrg_ The address of the new IP Org contract.
    /// @param name_ Descriptive name for the new IP Org contract.
    /// @param symbol_ A describe symbol for the new IP Org contract.
    event IPOrgRegistered(
        address owner_,
        address ipAssetOrg_,
        string name_,
        string symbol_
    );

    /// @notice Emits when an IP Org is transferred to a new owner.
    /// @param ipOrg_ The address of the IP Org.
    /// @param prevOwner_ The address of the previous owner of the IP Org.
    /// @param newOwner_ The address of the new owner of the IP Org.
    event IPOrgTransferred(
        address ipOrg_,
        address prevOwner_,
        address newOwner_
    );

    /// @notice Emits when an ownership transfer is initialized for a new owner.
    /// @param ipOrg_ The address of the IP Org.
    /// @param pendingOwner_ The pending owner to set for the IP Org.
    event IPOrgPendingOwnerSet(
        address ipOrg_,
        address pendingOwner_
    );

    /// @notice Registers a new IP Org.
    /// @param owner_ The address of the IP Org owner.
    /// @param name_ Metadata name to attach to the IP Org.
    /// @param symbol_ Metadata symbol to attach to the IP Org.
    function registerIpOrg(
       address owner_,
        string calldata name_,
        string calldata symbol_
    ) external returns(address);

    /// @notice Checks whether an IP Org exists.
    function isIpOrg(address ipOrg_) external view returns (bool);
}
