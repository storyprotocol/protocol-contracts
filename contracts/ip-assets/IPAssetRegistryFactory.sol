// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.13;

import { IIPAssetRegistry } from "contracts/interfaces/ip-assets/IIPAssetRegistry.sol";
import { IPAssetRegistry } from "./IPAssetRegistry.sol";
import { IVersioned } from "contracts/interfaces/utils/IVersioned.sol";
import { UnsupportedInterface } from "../errors/General.sol";
import { LicenseRegistry } from "../modules/licensing/LicenseRegistry.sol";
import { RevertingIPAssetRegistry } from "contracts/utils/RevertingIPAssetRegistry.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import { BeaconProxy } from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

contract IPAssetRegistryFactory is Ownable {
    using ERC165Checker for address;

    event FranchiseCreated(
        address indexed collection,
        string name,
        string indexed symbol
    );
    event FranchisesUpgraded(address indexed newImplementation, string version);

    UpgradeableBeacon public immutable BEACON;

    constructor() {
        // NOTE: Franchise creation won't work until the beacon is upgraded
        BEACON = new UpgradeableBeacon(address(new RevertingIPAssetRegistry()));
    }

    function createFranchiseIPAssets(
        uint256 franchiseId,
        string calldata name,
        string calldata symbol,
        string calldata description
    ) external returns (address) {
        bytes memory data = abi.encodeWithSelector(
            bytes4(
                keccak256(bytes("initialize(uint256,string,string,string)"))
            ),
            franchiseId,
            name,
            symbol,
            description
        );
        address proxy = address(new BeaconProxy(address(BEACON), data));
        LicenseRegistry licenseRegistry = new LicenseRegistry(
            proxy,
            string.concat("Licenses for ", name),
            string.concat("sl", symbol)
        );
        IPAssetRegistry(proxy).setLicenseRegistry(address(licenseRegistry));
        emit FranchiseCreated(proxy, name, symbol);
        return proxy;
    }

    function upgradeFranchises(address newImplementation) external onlyOwner {
        if (
            !newImplementation.supportsInterface(
                type(IIPAssetRegistry).interfaceId
            )
        ) {
            revert UnsupportedInterface("IIPAssetRegistry");
        }
        BEACON.upgradeTo(newImplementation);
        emit FranchisesUpgraded(
            address(newImplementation),
            IVersioned(newImplementation).version()
        );
    }
}
