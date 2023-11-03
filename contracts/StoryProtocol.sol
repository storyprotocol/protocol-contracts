// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IIPOrgFactory } from "contracts/interfaces/ip-org/IIPOrgFactory.sol";
import { IPOrgParams } from "contracts/lib/IPOrgParams.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { IPOrgParams } from "contracts/lib/IPOrgParams.sol";

contract StoryProtocol {
    // TODO: should this be immutable, or should the protocol be able to change factory
    IIPOrgFactory public immutable FACTORY;

    constructor(IIPOrgFactory ipOrgFactory_) {
        if (address(ipOrgFactory_) == address(0)) {
            revert Errors.ZeroAddress();
        }
        FACTORY = ipOrgFactory_;
    }

    function registerIpOrg(IPOrgParams.RegisterIpOrgParams calldata params) external returns (address) {
        return FACTORY.registerIpOrg(params);
    }

}