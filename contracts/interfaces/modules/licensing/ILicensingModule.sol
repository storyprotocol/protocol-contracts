// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Licensing } from "contracts/lib/modules/Licensing.sol";

/// @title ILicensingModule
interface ILicensingModule {

    /// Emits when an IP org picks a licensing framework
    /// and sets its configuration.
    /// @param ipOrg address of the IP org
    /// @param frameworkId the ID of the licensing framework
    /// @param url to the legal document
    /// @param licensorConfig the configuration of the licensor
    /// @param values the values of the parameters (tag and bytes value)
    event IpOrgLicensingFrameworkSet(
        address indexed ipOrg,
        string frameworkId,
        string url,
        Licensing.LicensorConfig licensorConfig,
        Licensing.ParamValue[] values
    );

    /// Gets the licensing framework of an IP org.
    function getIpOrgLicensorConfig(address ipOrg_) external view returns (Licensing.LicensorConfig);

    /// Gets the value set by an IP org for a parameter of a licensing framework.
    /// If no value is set (bytes.length==0), licensors will be able to set their value.
    /// @param ipOrg_ address of the IP org
    /// @param paramTag_ string tag of the parameter
    function getIpOrgValueForParam(
        address ipOrg_,
        string calldata paramTag_
    ) external view returns (bytes memory);
}
