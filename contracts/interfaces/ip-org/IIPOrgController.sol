// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice IP Org Controller Interface
interface IIPOrgController {
    /// @notice Emits when a new IP Org is registered.
    /// @param owner The address of the IP Org owner.
    /// @param ipAssetOrg The address of the new IP Org contract.
    /// @param name Descriptive name for the new IP Org contract.
    /// @param symbol A describe symbol for the new IP Org contract.
    /// @param ipAssetTypes String descriptors of the IP asset types available.
    event IPOrgRegistered(address owner, address ipAssetOrg, string name, string symbol, string[] ipAssetTypes);

    /// @notice Emits when an IP Org is transferred to a new owner.
    /// @param ipOrg The address of the IP Org.
    /// @param prevOwner The address of the previous owner of the IP Org.
    /// @param newOwner The address of the new owner of the IP Org.
    event IPOrgTransferred(address ipOrg, address prevOwner, address newOwner);

    /// @notice Emits when an ownership transfer is initialized for a new owner.
    /// @param ipOrg The address of the IP Org.
    /// @param pendingOwner The pending owner to set for the IP Org.
    event IPOrgPendingOwnerSet(address ipOrg, address pendingOwner);

    /// @notice Registers a new IP Org.
    /// @param owner_ The address of the IP Org owner.
    /// @param name_ Metadata name to attach to the IP Org.
    /// @param symbol_ Metadata symbol to attach to the IP Org.
    /// @param ipAssetTypes_ String descriptors of the IP asset types available.
    function registerIpOrg(
        address owner_,
        string calldata name_,
        string calldata symbol_,
        string[] calldata ipAssetTypes_
    ) external returns (address);

    /// @notice Checks whether an IP Org exists.
    function isIpOrg(address ipOrg_) external view returns (bool);
}
