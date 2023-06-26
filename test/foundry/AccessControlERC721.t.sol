// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import './utils/ProxyHelper.sol';
import 'contracts/utils/AccessControlERC721.sol';

contract AccessControlERC721Harness is AccessControlERC721 {

    function initialize(string calldata name, string calldata symbol) public initializer {
        __AccessControlERC721_init(name, symbol);
    }

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }

}

contract AccessControlERC721Test is Test, ProxyHelper {

    event RoleAdminChanged(uint256 indexed id, bytes32 indexed role, bytes32 previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(uint256 indexed id, bytes32 indexed role, address indexed account, address sender);
    event RoleRevoked(uint256 indexed id, bytes32 indexed role, address indexed account, address sender);

    AccessControlERC721Harness access;
    bytes32 constant NFT_OWNER_ROLE = 0x00;
    bytes32 constant ROLE_A = keccak256("ROLE_A");
    address owner = address(0x123);
    address roleAHolder = address(0x456);
    bytes32 constant ROLE_B = keccak256("ROLE_B");
    address roleBHolder = address(0x789);

    function setUp() public {
        AccessControlERC721Harness impl = new AccessControlERC721Harness();
        
        access = AccessControlERC721Harness(
            _deployUUPSProxy(
                address(impl),
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize(string,string)"))), "name", "symbol"
                )
            )
        );
        access.mint(owner, 1);

    }

    function test_roleKeyCalculation() public {
        assertEq(access.getRoleKey(1, ROLE_A), keccak256(abi.encode(1, ROLE_A)));
    }

    function test_setup() public {
        assertEq(access.name(), "name");
        assertEq(access.symbol(), "symbol");
    }

    /*************** hasRole and ownership ***************/

    function test_ownerHasRole() public {
        assertTrue(access.hasRole(1, NFT_OWNER_ROLE, owner), "owner should have NFT_OWNER_ROLE");
        assertEq(access.ownerOf(1), owner, "owner should own token");
    }

    function test_otherAddressIsNotRole() public { 
        assertFalse(access.hasRole(1, NFT_OWNER_ROLE, roleAHolder));
        assertFalse(access.ownerOf(1) == roleAHolder);
    }

    function test_nftOwnerIsRoleAdminOfItself() public {
        assertEq(access.getAdminRolekey(1, NFT_OWNER_ROLE), NFT_OWNER_ROLE);
    }

    /*************** Granting roles ***************/

    function test_grantRole() public {
        vm.expectEmit(true, true, true, true);
        emit RoleGranted(1, ROLE_A, roleAHolder, owner);
        vm.prank(owner);
        access.grantRole(1, ROLE_A, roleAHolder);
        assertTrue(access.hasRole(1, ROLE_A, roleAHolder));
        access.mint(owner, 2);
        vm.prank(owner);
        access.grantRole(2, ROLE_A, address(0x727));

        assertTrue(access.hasRole(2, ROLE_A, address(0x727)));
        assertFalse(access.hasRole(1, ROLE_A, address(0x727)));
        assertTrue(access.hasRole(1, ROLE_A, roleAHolder));
        assertFalse(access.hasRole(2, ROLE_A, roleAHolder));
    }

    function test_revertGrantingNotOwnerOrRoleAdmin() public {
        vm.expectRevert(); // TODO: check how to expect revert for custom errors with specific arguments
        access.grantRole(1, ROLE_A, roleAHolder);
    }

    function test_revertGrantingRoleHorizontally() public {
        vm.prank(owner);
        access.grantRole(1, ROLE_A, roleAHolder);
        vm.expectRevert();
        vm.prank(roleAHolder);
        access.grantRole(1, ROLE_A, address(0x727));
    }

    function test_revertGrantingNFT_OWNER() public {
        vm.expectRevert();
        vm.prank(owner);
        access.grantRole(1, NFT_OWNER_ROLE, roleAHolder);
    }

    function test_revertGrantingNonExistingId() public {
        vm.expectRevert("ERC721: invalid token ID");
        vm.prank(owner);
        access.grantRole(2, ROLE_A, roleAHolder);
    }

    /*************** Setting admin roles ***************/

    function test_setAdminRole() public {
        vm.prank(owner);
        vm.expectEmit(true ,true, true, true);
        emit RoleAdminChanged(1, ROLE_B, NFT_OWNER_ROLE, keccak256(abi.encode(1, ROLE_A)));
        access.setRoleAdmin(1, ROLE_B, ROLE_A);
        assertEq(access.getAdminRolekey(1, ROLE_A), NFT_OWNER_ROLE);
        assertEq(access.getAdminRolekey(1, ROLE_B), keccak256(abi.encode(1, ROLE_A)));
    }

}

