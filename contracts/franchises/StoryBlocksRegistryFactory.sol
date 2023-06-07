// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.13;

import { IStoryBlocksRegistry } from "./IStoryBlocksRegistry.sol";
import { StoryBlocksRegistry } from "./StoryBlocksRegistry.sol";
import { ZeroAddress } from "../errors/General.sol";
import { IVersioned } from "../utils/IVersioned.sol";
import { UnsupportedInterface } from "../errors/General.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol"; 
import { BeaconProxy } from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";


contract StoryBlocksRegistryFactory is Ownable {
    using ERC165Checker for address;

    event FranchiseCreated(address indexed collection, string name, string indexed symbol);
    event FranchisesUpgraded(address indexed newImplementation, string version);

    UpgradeableBeacon public immutable BEACON;

    constructor() {
        BEACON = new UpgradeableBeacon(address(new StoryBlocksRegistry()));
    }

    function createFranchise(
        string calldata name,
        string calldata symbol,
        string calldata description
    ) external returns (address) {
        bytes memory data = abi.encodeWithSelector(
            bytes4(keccak256(bytes("initialize(string,string,string)"))),
            name,
            symbol,
            description
        );
        address proxy = address(new BeaconProxy(address(BEACON), data));
        emit FranchiseCreated(proxy, name, symbol);
        return proxy;
    }

    function upgradeFranchises(address newImplementation) external onlyOwner {
        if (!newImplementation.supportsInterface(type(IStoryBlocksRegistry).interfaceId)) revert UnsupportedInterface("IStoryBlocksRegistry");
        BEACON.upgradeTo(newImplementation);
        emit FranchisesUpgraded(address(newImplementation), IVersioned(newImplementation).version());
    }
}
