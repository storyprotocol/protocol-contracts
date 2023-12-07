// SPDX-License-Identifier: UNLICENSED
// See Story Protocol Alpha Agreement: https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

contract BaseTestUtils is Test {

    // Test public keys EOAs that may be reused for testing and deriving EOAs.
    uint256 internal alicePk = 0xa11ce;
    uint256 internal bobPk = 0xb0b;
    uint256 internal calPk = 0xca1;

    // Test EOA addresses that may be reused for testing.
    address payable internal alice = payable(vm.addr(alicePk));
    address payable internal bob = payable(vm.addr(bobPk));
    address payable internal cal = payable(vm.addr(calPk));

    /// @notice Modifier that ensures that a receiver address does not happen
    ///         to be a built-in foundry contract that breaks EOA assumptions.
    modifier isValidReceiver(address receiver) {
        vm.assume(receiver != 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D); // HEVM Address
        vm.assume(receiver != 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496); // Foundry Test Contract
        vm.assume(receiver != 0x4e59b44847b379578588920cA78FbF26c0B4956C); // CREATE2 Deployer
        vm.assume(receiver != 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f);
        vm.assume(receiver != 0x104fBc016F4bb334D775a19E8A6510109AC63E00);
        _;
    }

    /// @notice Helper function that allows running "subtests" that revert back
    ///         to a snapshotted state after being run.
    modifier stateless() {
        uint256 snapshot = vm.snapshot();
        _;
        vm.revertTo(snapshot);
    }

    function setUp() public virtual {
        vm.label(alice, "alice");
        vm.label(bob, "bob");
        vm.label(cal, "cal");
    }

}
