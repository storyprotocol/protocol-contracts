// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { SPAssetNFTFactory } from "./sp-assets/SPAssetNFTFactory.sol";
import { AccessControlled } from "./access-control/AccessControlled.sol";
import { UPGRADER_ROLE } from "./access-control/ProtocolRoles.sol";
import { ZeroAddress } from "./errors/General.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract SPRegister is UUPSUpgradeable, AccessControlled {

    enum RegisterType {
        UNDEFINED,
        FRANCHISE,
        STORY,
        CHARACTER,
        ART,
        GROUP,
        LOCATION,
        LENGTH
    }

    struct Register {
        string name;
        string description;
        string url;
        RegisterType regType;
    }
    
    mapping(uint256 => mapping(address => Register)) public _registered;
    address public rootFranchiseAddress;

    SPAssetNFTFactory public immutable factory;

    constructor(address _factory) {
        _disableInitializers();
        if (_factory == address(0)) revert ZeroAddress("factory");
        factory = SPAssetNFTFactory(_factory);
    }

    function initialize(address accessControl) public initializer {
        __UUPSUpgradeable_init();
        __AccessControlled_init(accessControl);
        _createRootFranchise();
    }

    function _createRootFranchise() internal {
        // if already SPRegistered, revert
        address rootFranchiseCollection = factory.createCollection("Story Protocol", "SP");
        _registered[0][rootFranchiseCollection] = Register({
            name: "Story Protocol",
            description: "The nexus of the narrative multiverse",
            url: "https://story-protocol.io",
            regType: RegisterType.FRANCHISE
        });
    }

    function rootFranchise() external view returns (Register memory) {
        return _registered[0][rootFranchiseAddress];
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyRole(UPGRADER_ROLE) {
    }

}