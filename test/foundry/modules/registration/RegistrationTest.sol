// SPDX-License-Identifier: BUSL-1.1
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
        uint64 indexed ipAssetType_,
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
        uint64 indexed ipAssetType_,
        bytes32 hash_
    );

    // Id of IP asset which may differ per test based on testing constraints.
    uint256 ipAssetId;
    address payable registrant;

    /// @notice Modifier that creates an IP asset for testing.
    /// @param ipAssetOwner The owner address for the new IP asset.
    /// @param ipAssetType The type of the IP asset being created.
    modifier createIpAsset(address ipAssetOwner, uint8 ipAssetType) virtual {
        ipAssetId = _createIpAsset(ipAssetOwner, ipAssetType, "");
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
        assertEq(registrationModule.tokenURI(address(ipOrg), 0), "https://storyprotocol.xyz/0");
    }

    /// @notice Tests the default token URI for IPAs.
    function test_RegistrationModuleDefaultIPOrgMetadata() public virtual createIpAsset(registrant, 0) {
        IPAssetRegistry.IPA memory ipa = registry.ipAsset(0);
        string memory ipOrgStr = Strings.toHexString(uint160(address(ipOrg)), 20);
        string memory registrantStr = Strings.toHexString(uint160(address(registrant)), 20);

        string memory part1 = string(abi.encodePacked(
            '{"name": "Global IP Asset #0", "description": "IP Org Asset Registration Details", "attributes": [',
            '{"trait_type": "Name", "value": "TestIPAsset"},',
            '{"trait_type": "IP Org", "value": "', ipOrgStr, '"},',
            '{"trait_type": "Current IP Owner", "value": "', registrantStr, '"},',
            '{"trait_type": "Initial Registrant", "value": "', registrantStr, '"},'
        ));

        string memory part2 = string(abi.encodePacked(
            '{"trait_type": "IP Asset Type", "value": "0"},',
            '{"trait_type": "Status", "value": "0"},',
            '{"trait_type": "Hash", "value": "0x0000000000000000000000000000000000000000000000000000000000000000"},',
            '{"trait_type": "Registration Date", "value": "', Strings.toString(ipa.registrationDate), '"}'
            ']}'
        ));
        string memory expectedURI = string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(bytes(string(abi.encodePacked(part1, part2))))
        ));
        assertEq(expectedURI, registrationModule.tokenURI(address(ipOrg), 0));

    }

    /// @notice Tests IP Asset registration.
    function test_RegistrationModuleIPARegistration() public virtual {
        vm.prank(cal);
        vm.expectEmit(true, true, true, true, address(registry));
        emit Registered(
            0,
            "TestIPA",
            0,
            address(ipOrg),
            cal,
            ""
        );
        vm.expectEmit(true, true, true, true, address(registrationModule));
        emit IPAssetRegistered(
            0,
            address(ipOrg),
            0,
            cal,
            "TestIPA",
            0,
            ""
        );
        _register(address(ipOrg), cal, "TestIPA", 0, "");
        assertEq(registry.ipAssetOwner(0), cal);
        assertEq(ipOrg.ownerOf(0), cal);
    }

    /// @notice Tests whether collect reverts if the IP asset being collected from does not exist.
    // function test_CollectModuleCollectNonExistentIPAssetReverts(uint256 nonExistentipAssetId, uint8 ipAssetType) createIpAsset(collector, ipAssetType) public virtual {
    //     vm.assume(nonExistentipAssetId != ipAssetId);
    //     vm.expectRevert(Errors.CollectModule_IPAssetNonExistent.selector);
    //     _collect(nonExistentipAssetId);
    // }

    // /// @notice Tests that collects with the module-default collect NFT succeed.
    // function test_CollectModuleCollectDefaultCollectNFT(uint8 ipAssetType) createIpAsset(collector, ipAssetType) public {
    //     assertEq(collectModule.getCollectNFT(ipAssetId), address(0));
    //     vm.expectEmit(true, true, false, false, address(collectModule));
    //     emit NewCollectNFT(
    //         ipAssetId,
    //         defaultCollectNftImpl
    //     );
    //     vm.expectEmit(true, true, true, false, address(collectModule));
    //     emit Collected(
    //         ipAssetId,
    //         collector,
    //         defaultCollectNftImpl,
    //         0,
    //         "",
    //         ""
    //     );
    //     (address collectNft, uint256 collectNftId) = _collect(ipAssetId);
    //     assertEq(collectModule.getCollectNFT(ipAssetId), collectNft);
    //     assertTrue(ICollectNFT(collectNft).ownerOf(collectNftId) == cal);
    //     assertEq(collectModule.getCollectNFT(ipAssetId), collectNft);
    // }

    // /// @notice Tests that collects with customized collect NFTs succeed.
    // function test_CollectModuleCollectCustomCollectNFT(uint8 ipAssetType) public createIpAsset(collector, ipAssetType) {
    //     assertEq(collectModule.getCollectNFT(ipAssetId), address(0));
    //     vm.expectEmit(true, true, false, false, address(collectModule));
    //     emit NewCollectNFT(
    //         ipAssetId,
    //         defaultCollectNftImpl
    //     );
    //     vm.expectEmit(true, true, true, false, address(collectModule));
    //     emit Collected(
    //         ipAssetId,
    //         collector,
    //         defaultCollectNftImpl,
    //         0,
    //         "",
    //         ""
    //     );
    //     (address collectNft, uint256 collectNftId) = _collect(ipAssetId);
    //     assertEq(collectModule.getCollectNFT(ipAssetId), collectNft);
    //     assertTrue(ICollectNFT(collectNft).ownerOf(collectNftId) == cal);
    // }

    // /// @notice Tests expected behavior of the collect module constructor.
    // function test_CollectModuleConstructor() public {
    //     MockCollectModule mockCollectModule = new MockCollectModule(address(registry), defaultCollectNftImpl);
    //     assertEq(address(mockCollectModule.REGISTRY()), address(registry));
    // }

    // /// @notice Tests expected behavior of collect module initialization.
    // function test_CollectModuleInit() public {
    //     assertEq(address(0), collectModule.getCollectNFT(ipAssetId));
    // }

    // /// @notice Tests collect module reverts on unauthorized calls.
    // function test_CollectModuleInitCollectInvalidCallerReverts(uint256 nonExistentIPOrgId, uint8 ipAssetType) public createIpAsset(collector, ipAssetType)  {
    //     vm.expectRevert(Errors.CollectModule_CallerUnauthorized.selector);
    //     vm.prank(address(this));
    //     collectModule.initCollect(Collect.InitCollectParams({
    //         ipAssetId: ipAssetId,
    //         collectNftImpl: defaultCollectNftImpl,
    //         data: ""
    //     }));
    // }

    // /// @notice Tests collect module reverts on duplicate initialization.
    // function test_CollectModuleDuplicateInitReverts(uint8 ipAssetType) createIpAsset(collector, ipAssetType) public {
    //     vm.expectRevert(Errors.CollectModule_IPAssetAlreadyInitialized.selector);
    //     vm.prank(address(ipOrg));
    //     _initCollectModule(defaultCollectNftImpl);
    // }

    /// @dev Helper function that performs registration.
    /// @param ipOrg_ Address of the ipOrg of the IP asset.
    /// @param owner_ Address of the owner of the IP asset.
    /// @param name_ Name of the IP asset.
    /// @param ipAssetType_ Type of the IP asset.
    /// @param hash_ Content has of the IP Asset.
    function _register(
        address ipOrg_,
        address owner_,
        string memory name_,
        uint64 ipAssetType_,
        bytes32 hash_
    ) internal virtual returns (uint256, uint256) {
        Registration.RegisterIPAssetParams memory params = Registration.RegisterIPAssetParams({
            owner: owner_,
            name: name_,
            ipAssetType: ipAssetType_, 
            hash: hash_
        });
        bytes[] memory hooks = new bytes[](0);
        return spg.registerIPAsset(address(ipOrg), params, hooks, hooks);
    }

}
