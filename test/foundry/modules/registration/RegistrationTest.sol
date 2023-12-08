// SPDX-License-Identifier: UNLICENSED
// See Story Protocol Alpha Agreement: https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.18;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";
import { IRegistrationModule } from "contracts/interfaces/modules/registration/IRegistrationModule.sol";

import { Registration } from "contracts/lib/modules/Registration.sol";
import { IPAssetRegistry } from "contracts/IPAssetRegistry.sol";
import { BaseTestUtils } from "test/foundry/utils/BaseTestUtils.sol";
import { BaseTest } from "test/foundry/utils/BaseTest.sol";
// import { MockRegistrationModule } from "test/foundry/mocks/MockCollectModule.sol";

import { Errors } from "contracts/lib/Errors.sol";

/// @title Registration Module Testing Contract
contract RegistrationModuleTest is BaseTest {

    // TODO: Currently, when compiling with 0.8.21, there is a known ICE bug that prevents us from emitting from the interface directly e.g. via IIPAssetRegistry.Registered - these two should be refactored in favor of emitting through the interface once we officially migrate to 0.8.22.

    event Registered(
        uint256 ipAssetId_,
        string name_,
        address indexed ipOrg_,
        address indexed registrant_,
        bytes32 hash_
    );

    event IPAssetRegistered(
        uint256 ipAssetId_,
        address indexed ipOrg_,
        uint256 ipOrgAssetId_,
        address indexed owner_,
        string name_,
        uint8 indexed ipOrgAssetType_,
        bytes32 hash_,
        string mediaUrl_
    );

    // Id of IP asset which may differ per test based on testing constraints.
    uint256 ipAssetId;
    address payable registrant;

    /// @notice Modifier that creates an IP asset for testing.
    /// @param ipAssetOwner The owner address for the new IP asset.
    /// @param ipAssetType The type of the IP asset being created.
    modifier createIpAsset(address ipAssetOwner, uint8 ipAssetType) virtual {
        (ipAssetId, ) = _createIpAsset(ipAssetOwner, ipAssetType, "");
        _;
    }

    /// @notice Sets up the base collect module for running tests.
    function setUp() public virtual override(BaseTest) { 
        super.setUp();
        registrant = cal;
    }

    /// @notice Tests custom token URI override for IPOrgs.
    function test_RegistrationModuleSetMetadata() public virtual createIpAsset(registrant, 0) {
        address ipOrgOwner = ipOrg.owner();
        vm.prank(ipOrgOwner);
        spg.setMetadata(
            address(ipOrg),
            "https://storyprotocol.xyz/",
            "https://storyprotocol.xyz"
        );
        assertEq(registrationModule.tokenURI(address(ipOrg), 1, 0), "https://storyprotocol.xyz/1");
    }

    /// @notice Tests the default token URI for IPAs.
    function test_RegistrationModuleDefaultIPOrgMetadata() public virtual createIpAsset(registrant, 0) {
        IPAssetRegistry.IPA memory ipa = registry.ipAsset(1);
        string memory ipOrgStr = Strings.toHexString(uint160(address(ipOrg)), 20);
        string memory registrantStr = Strings.toHexString(uint160(address(registrant)), 20);

        string memory part1 = string(abi.encodePacked(
            '{"name": "Global IP Asset #1", "description": "IP Org Asset Registration Details", "attributes": [',
            '{"trait_type": "Name", "value": "TestIPAsset"},',
            '{"trait_type": "IP Org", "value": "', ipOrgStr, '"},',
            '{"trait_type": "Current IP Owner", "value": "', registrantStr, '"},',
            '{"trait_type": "Initial Registrant", "value": "', registrantStr, '"},'
        ));

        string memory part2 = string(abi.encodePacked(
            '{"trait_type": "IP Org Asset Type", "value": "CHARACTER"},',
            '{"trait_type": "Status", "value": "1"},',
            '{"trait_type": "Hash", "value": "0x0000000000000000000000000000000000000000000000000000000000000000"},',
            '{"trait_type": "Registration Date", "value": "', Strings.toString(ipa.registrationDate), '"}'
            ']}'
        ));
        string memory expectedURI = string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(bytes(string(abi.encodePacked(part1, part2))))
        ));
        assertEq(expectedURI, registrationModule.tokenURI(address(ipOrg), 1, 0));

    }

    /// @notice Tests IP Asset registration.
    function test_RegistrationModuleIPARegistration() public virtual {
        vm.prank(cal);
        vm.expectEmit(true, true, true, true, address(registry));
        emit Registered(
            1,
            "TestIPA",
            address(ipOrg),
            cal,
            ""
        );
        vm.expectEmit(true, true, true, true, address(registrationModule));
        emit IPAssetRegistered(
            1,
            address(ipOrg),
            1,
            cal,
            "TestIPA",
            0,
            "",
            ""
        );
        _register(address(ipOrg), cal, "TestIPA", 0, "", "");
        assertEq(registry.ipAssetOwner(1), cal);
        assertEq(ipOrg.ownerOf(1), cal);
    }

    /// @notice Tests IP Asset registration with media URL.
    function test_RegistrationModuleIPARegistrationWithMediaUrl() public virtual {
        string memory mediaUrl = "http://token.url";
        vm.prank(cal);
        vm.expectEmit(true, true, true, true, address(registry));
        emit Registered(
            1,
            "TestIPA",
            address(ipOrg),
            cal,
            ""
        );
        vm.expectEmit(true, true, true, true, address(registrationModule));
        emit IPAssetRegistered(
            1,
            address(ipOrg),
            1,
            cal,
            "TestIPA",
            0,
            "",
            mediaUrl
        );
        _register(address(ipOrg), cal, "TestIPA", 0, "", mediaUrl);
        assertEq(registry.ipAssetOwner(1), cal, "ipa owner");
        assertEq(ipOrg.ownerOf(1), cal, "iporg owner");
        assertEq(mediaUrl, registrationModule.tokenURI(address(ipOrg), 1, 0), "media url");
    }

    /// @dev Helper function that performs registration.
    /// @param ipOrg_ Address of the ipOrg of the IP asset.
    /// @param owner_ Address of the owner of the IP asset.
    /// @param name_ Name of the IP asset.
    /// @param ipOrgAssetType_ Type of the IP asset.
    /// @param hash_ Content has of the IP Asset.
    function _register(
        address ipOrg_,
        address owner_,
        string memory name_,
        uint8 ipOrgAssetType_,
        bytes32 hash_,
        string memory mediaUrl_
    ) internal virtual returns (uint256, uint256) {
        Registration.RegisterIPAssetParams memory params = Registration.RegisterIPAssetParams({
            owner: owner_,
            name: name_,
            ipOrgAssetType: ipOrgAssetType_, 
            hash: hash_,
            mediaUrl: mediaUrl_
        });
        bytes[] memory hooks = new bytes[](0);
        return spg.registerIPAsset(address(ipOrg), params, 0, hooks, hooks);
    }

}
