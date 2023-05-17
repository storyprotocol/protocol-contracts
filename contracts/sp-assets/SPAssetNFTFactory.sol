// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {SPAssetNFT} from "./SPAssetNFT.sol";
import {ZeroAddress} from "../errors/General.sol";

contract SPAssetNFTFactory is Ownable {
    address public immutable template;
    UpgradeableBeacon public immutable beacon;

    constructor() {
        template = address(new SPAssetNFT());
        beacon = new UpgradeableBeacon(template);
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
        address proxy = address(new BeaconProxy(address(beacon), data));
        return proxy;
    }

    function upgradeBeacons(address newImplementation) external onlyOwner {
        if (newImplementation == address(0))
            revert ZeroAddress("newImplementation");
        beacon.upgradeTo(newImplementation);
    }
}
