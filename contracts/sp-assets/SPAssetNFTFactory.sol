// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.13;

import { ISPAssetNFT } from "./ISPAssetNFT.sol";
import { SPAssetNFT } from "./SPAssetNFT.sol";
import { ZeroAddress } from "../errors/General.sol";
import { IVersioned } from "../utils/IVersioned.sol";
import { UnsupportedInterface } from "../errors/General.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol"; 
import { BeaconProxy } from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";


contract SPAssetNFTFactory is Ownable {
    using ERC165Checker for address;

    event CollectionCreated(address indexed collection, string name, string indexed symbol);
    event CollectionsUpgraded(address indexed newImplementation, string version);

    UpgradeableBeacon public immutable BEACON;

    constructor() {
        BEACON = new UpgradeableBeacon(address(new SPAssetNFT()));
    }

    function createCollection(
        string calldata name,
        string calldata symbol
    ) external returns (address) {
        bytes memory data = abi.encodeWithSelector(
            bytes4(keccak256(bytes("initialize(string,string)"))),
            name,
            symbol
        );
        address proxy = address(new BeaconProxy(address(BEACON), data));
        emit CollectionCreated(proxy, name, symbol);
        return proxy;
    }

    function upgradeCollections(address newImplementation) external onlyOwner {
        if (!newImplementation.supportsInterface(type(ISPAssetNFT).interfaceId)) revert UnsupportedInterface("ISPAssetNFT");
        BEACON.upgradeTo(newImplementation);
        emit CollectionsUpgraded(address(newImplementation), IVersioned(newImplementation).version());
    }
}
