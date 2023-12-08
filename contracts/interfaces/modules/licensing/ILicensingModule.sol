// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IModule } from "contracts/interfaces/modules/base/IModule.sol";
import { Licensing } from "contracts/lib/modules/Licensing.sol";

/// @title Licensing Module Interface
interface ILicensingModule is IModule {
    /// Emits when an IP org picks a licensing framework and sets its configuration.
    /// @param ipOrg Address of the IP org whose license framework is being set.
    /// @param frameworkId The uint256 id of the set licensing framework.
    /// @param url A string URL which points to the associated legal document.
    /// @param licensorConfig Configuration associated with the framework's licensor.
    /// @param values A list of terms describing the licensing framework.
    event IpOrgLicensingFrameworkSet(
        address indexed ipOrg,
        string frameworkId,
        string url,
        Licensing.LicensorConfig licensorConfig,
        Licensing.ParamValue[] values
    );

    /// @notice Gets the licensing framework for an IP org.
    /// @param ipOrg_ The address of the selected IP Org.
    function getIpOrgLicensorConfig(address ipOrg_) external view returns (Licensing.LicensorConfig);

    /// Gets the value set by an IP org for a parameter of a licensing framework.
    /// If no value is set (bytes.length==0), licensors will be able to set their value.
    /// @param ipOrg_ address of the IP org
    /// @param paramTag_ string tag of the parameter
    function getIpOrgValueForParam(address ipOrg_, string calldata paramTag_) external view returns (bytes memory);
}
