// SPDX-License-Identifier: UNLICENSED
// See Story Protocol Alpha Agreement: https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.18;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ICollectModule } from "contracts/interfaces/modules/collect/ICollectModule.sol";
import { ICollectPaymentModule } from "contracts/interfaces/modules/collect/ICollectPaymentModule.sol";
import { ICollectNFT } from "contracts/interfaces/modules/collect/ICollectNFT.sol";

import { BaseCollectModuleTest } from "./BaseCollectModuleTest.sol";
import { BaseTest } from "test/foundry/utils/BaseTest.sol";
import { MockCollectPaymentModule } from "mvp/test/foundry/mocks/MockCollectPaymentModule.sol";
import { MockNativeTokenNonReceiver } from "test/foundry/mocks/MockNativeTokenNonReceiver.sol";
import { MockThrowingERC20 } from "test/foundry/mocks/MockThrowingERC20.sol";
import { MockCollectNFT } from "mvp/test/foundry/mocks/MockCollectNFT.sol";
import { MockERC20 } from "test/foundry/mocks/MockERC20.sol";
import { MockWETH } from "test/foundry/mocks/MockWETH.sol";

import { Collect } from "contracts/lib/modules/Collect.sol";
import { Errors } from "contracts/lib/Errors.sol";

/// @title Collect Payment Module Base Testing Contract
/// @notice Tests all functionality provided by the base payment collect module.
contract CollectPaymentModuleBaseTest is BaseCollectModuleTest {

    ICollectPaymentModule collectPaymentModule;

    MockERC20 public erc20;
    MockWETH public weth;

    address paymentToken;
    Collect.PaymentType paymentType;
    uint256 paymentAmount;
    address payable paymentRecipient;
    Collect.CollectPaymentInfo paymentInfo;
    Collect.CollectPaymentParams paymentParams;

    // Used for mocking suites of tests involving payment infos and params.
    CollectPaymentSet[] paymentSets;

    struct CollectPaymentSet {
        Collect.CollectPaymentInfo info;
        Collect.CollectPaymentParams params;
    }

    /// @notice Parameterizes payment inputs and outputs for multiple test runs.
    modifier parameterizePaymentInfo(CollectPaymentSet[] memory paymentInfoSuite) {
        uint256 length = paymentInfoSuite.length;
        for (uint256 i = 0; i < length; ) {
            paymentInfo = paymentInfoSuite[i].info;
            paymentParams = paymentInfoSuite[i].params;
            (ipAssetId, ) = _createIpAsset(alice, 1, abi.encode(paymentInfo));
            _;
            i += 1;
        }
    }

    /// @notice Modifier that creates an IP asset for normal collect testing,
    ///         using the latest generated payment struct for collect encoding.
    /// @param ipAssetOwner The owner address for the new IP asset.
    /// @param ipAssetType The type of the IP asset being created.
    modifier createIpAsset(address ipAssetOwner, uint8 ipAssetType) override {
        (ipAssetId, ) = _createIpAsset(ipAssetOwner, ipAssetType, abi.encode(paymentInfo));
        _;
    }

    /// @notice Sets up testing for the base collect payment module.
    function setUp() public virtual override(BaseCollectModuleTest) { 
        super.setUp();
        paymentToken = address(0);
        paymentType =  Collect.PaymentType.NATIVE;
        paymentAmount =  1 ether;
        paymentRecipient = alice;
        collector = cal;
        vm.deal(collector, 999 ether);
        paymentInfo = Collect.CollectPaymentInfo({
            paymentToken: paymentToken,
            paymentType: paymentType,
            paymentAmount: paymentAmount,
            paymentRecipient: paymentRecipient
        });
        paymentParams = Collect.CollectPaymentParams({
            paymentToken: paymentToken,
            paymentType: paymentType,
            paymentAmount: paymentAmount
        });
        erc20 = new MockERC20("Story Protocol Mock Token", "SP", 18);
        vm.startPrank(collector);
        erc20.mint(999999);
        erc20.approve(address(collectPaymentModule), type(uint256).max);
        weth = new MockWETH();
        weth.mint(999999);
        weth.approve(address(collectPaymentModule), type(uint256).max);
        vm.stopPrank();
    }

    // /// @notice Tests that the collect payment module is correctly initialized.
    // function test_CollectPaymentModuleInit() public parameterizePaymentInfo(paymentSuite()) {
    //     Collect.CollectPaymentInfo memory p = collectPaymentModule.getPaymentInfo(ipAssetId);
    //     assertEq(p.paymentToken, paymentInfo.paymentToken);
    //     assertEq(uint8(p.paymentType), uint8(paymentInfo.paymentType));
    //     assertEq(p.paymentAmount, paymentInfo.paymentAmount);
    //     assertEq(p.paymentRecipient, paymentInfo.paymentRecipient);
    // }

    // /// @notice Tests that native payments with no sent funds revert.
    // function test_CollectPaymentModuleZeroPaymentReverts() public {
    //     paymentInfo = Collect.CollectPaymentInfo(address(0), Collect.PaymentType.NATIVE, 0 ether, alice);
    //     vm.expectRevert(Errors.CollectPaymentModule_AmountInvalid.selector);
    //     _createIpAsset(collector, 1, abi.encode(paymentInfo));
    // }

    // /// @notice Tests that payments with invalid settings revert.
    // function test_CollectPaymentModuleInvalidSettingsReverts() public {
    //     paymentInfo = Collect.CollectPaymentInfo(address(erc20), Collect.PaymentType.NATIVE, 1 ether, alice);
    //     vm.expectRevert(Errors.CollectPaymentModule_InvalidSettings.selector);
    //     _createIpAsset(collector, 1, abi.encode(paymentInfo));
    // }

    // /// @notice Tests that payments with invalid tokens revert.
    // function test_CollectPaymentModuleInvalidTokenReverts() public {
    //     paymentInfo = Collect.CollectPaymentInfo(bob, Collect.PaymentType.ERC20, 1 ether, alice);
    //     vm.expectRevert(Errors.CollectPaymentModule_TokenInvalid.selector);
    //     _createIpAsset(collector, 1, abi.encode(paymentInfo));
    // }

    // /// @notice Tests that native payments work as expected.
    // function test_CollectPaymentModuleNativeCollect() public parameterizePaymentInfo(paymentSuiteNative()) {
    //     uint256 recipientStartingBalance = paymentRecipient.balance;
    //     uint256 collectorStartingBalance = collector.balance;
    //     paymentAmount = paymentParams.paymentAmount;
    //     _collect(ipAssetId);
    //     assertEq(collector.balance, collectorStartingBalance - paymentAmount);
    //     assertEq(paymentRecipient.balance, recipientStartingBalance + paymentAmount);
    // }

    // /// @notice Tests that native payments that fail revert.
    // function test_CollectPaymentModuleNativeTransferFailReverts() public {
    //     address payable throwingReceiver  = payable(address(new MockNativeTokenNonReceiver()));

    //     paymentInfo = Collect.CollectPaymentInfo({
    //         paymentToken: address(0),
    //         paymentType: Collect.PaymentType.NATIVE,
    //         paymentAmount: 10,
    //         paymentRecipient: throwingReceiver
    //     });
    //     paymentParams = Collect.CollectPaymentParams({
    //         paymentToken: address(0),
    //         paymentType: Collect.PaymentType.NATIVE,
    //         paymentAmount: 10
    //     });
    //     ipAssetId = _createIpAsset(collector, 1, abi.encode(paymentInfo));

    //     vm.prank(collector);
    //     vm.expectRevert(Errors.CollectPaymentModule_NativeTransferFailed.selector);
    //     collectModule.collect{value: 10}(Collect.CollectParams({
    //         ipAssetId: ipAssetId,
    //         collector: collector,
    //         collectData: abi.encode(paymentParams),
    //         collectNftInitData: "",
    //         collectNftData: ""
    //     }));
    // }

    // /// @notice Tests that payments with invalid parameters revert.
    // function test_CollectPaymentModuleInvalidPaymentParamsReverts() public {
    //     paymentInfo = Collect.CollectPaymentInfo({
    //         paymentToken: address(erc20),
    //         paymentType: Collect.PaymentType.ERC20,
    //         paymentAmount: 10,
    //         paymentRecipient: paymentRecipient
    //     });
    //     paymentParams = Collect.CollectPaymentParams({
    //         paymentToken: address(erc20),
    //         paymentType: Collect.PaymentType.ERC20,
    //         paymentAmount: 1
    //     });
    //     ipAssetId = _createIpAsset(collector, 1, abi.encode(paymentInfo));
    //     vm.expectRevert(Errors.CollectPaymentModule_PaymentParamsInvalid.selector);
    //     _collect(ipAssetId);
    // }

    // /// @notice Tests that ERC20 payments with failing transfers revert.
    // function test_CollectPaymentModuleERC20TransferFailReverts() public {
    //     MockThrowingERC20 throwingERC20 = new MockThrowingERC20("Story Protocol Mock Token", "SP", 18, MockThrowingERC20.TransferBehavior.Fail);
    //     vm.prank(collector);
    //     throwingERC20.mint(999999);
    //     paymentInfo = Collect.CollectPaymentInfo({
    //         paymentToken: address(throwingERC20),
    //         paymentType: Collect.PaymentType.ERC20,
    //         paymentAmount: 10,
    //         paymentRecipient: paymentRecipient
    //     });
    //     paymentParams = Collect.CollectPaymentParams({
    //         paymentToken: address(throwingERC20),
    //         paymentType: Collect.PaymentType.ERC20,
    //         paymentAmount: 10
    //     });
    //     ipAssetId = _createIpAsset(collector, 1, abi.encode(paymentInfo));
    //     vm.expectRevert(Errors.CollectPaymentModule_ERC20TransferFailed.selector);
    //     _collect(ipAssetId);
    // }

    // /// @notice Tests that ERC20 payments with invalid payments revert.
    // function test_CollectPaymentModuleERC20InvalidPaymentReverts() public {
    //     paymentInfo = Collect.CollectPaymentInfo({
    //         paymentToken: address(erc20),
    //         paymentType: Collect.PaymentType.ERC20,
    //         paymentAmount: 10,
    //         paymentRecipient: paymentRecipient
    //     });
    //     paymentParams = Collect.CollectPaymentParams({
    //         paymentToken: address(erc20),
    //         paymentType: Collect.PaymentType.ERC20,
    //         paymentAmount: 10
    //     });
    //     ipAssetId = _createIpAsset(collector, 1, abi.encode(paymentInfo));
    //     vm.expectRevert(Errors.CollectPaymentModule_NativeTokenNotAllowed.selector);
    //     collectModule.collect{value: 10}(Collect.CollectParams({
    //         ipAssetId: ipAssetId,
    //         collector: collector,
    //         collectData: abi.encode(paymentParams),
    //         collectNftInitData: "",
    //         collectNftData: ""
    //     }));
    // }

    // /// @notice Tests that ERC20 payments with insufficient funds revert.
    // function test_CollectPaymentModuleERC20InsufficientFundsReverts() public {
    //     paymentInfo = Collect.CollectPaymentInfo({
    //         paymentToken: address(erc20),
    //         paymentType: Collect.PaymentType.ERC20,
    //         paymentAmount: 9999999,
    //         paymentRecipient: paymentRecipient
    //     });
    //     paymentParams = Collect.CollectPaymentParams({
    //         paymentToken: address(erc20),
    //         paymentType: Collect.PaymentType.ERC20,
    //         paymentAmount: 9999999
    //     });
    //     ipAssetId = _createIpAsset(collector, 1, abi.encode(paymentInfo));
    //     vm.expectRevert(Errors.CollectPaymentModule_PaymentInsufficient.selector);
    //     _collect(ipAssetId);

    // }

    // /// @notice Tests that ERC20 payments with invalid ABI encoding revert.
    // function test_CollectPaymentModuleERC20TransferInvalidABIReverts() public {
    //     MockThrowingERC20 throwingERC20 = new MockThrowingERC20("Story Protocol Mock Token", "SP", 18, MockThrowingERC20.TransferBehavior.ReturnInvalidABI);
    //     vm.prank(collector);
    //     throwingERC20.mint(999999);
    //     paymentInfo = Collect.CollectPaymentInfo({
    //         paymentToken: address(throwingERC20),
    //         paymentType: Collect.PaymentType.ERC20,
    //         paymentAmount: 10,
    //         paymentRecipient: paymentRecipient
    //     });
    //     paymentParams = Collect.CollectPaymentParams({
    //         paymentToken: address(throwingERC20),
    //         paymentType: Collect.PaymentType.ERC20,
    //         paymentAmount: 10
    //     });
    //     ipAssetId = _createIpAsset(collector, 1, abi.encode(paymentInfo));
    //     vm.expectRevert(Errors.CollectPaymentModule_ERC20TransferInvalidABIEncoding.selector);
    //     _collect(ipAssetId);
    // }

    // /// @notice Tests that ERC20 payments with invalid return values revert.
    // function test_CollectPaymentModuleERC20TransferInvalidReturnReverts() public {
    //     MockThrowingERC20 throwingERC20 = new MockThrowingERC20("Story Protocol Mock Token", "SP", 18, MockThrowingERC20.TransferBehavior.ReturnFalse);
    //     vm.prank(collector);
    //     throwingERC20.mint(999999);
    //     paymentInfo = Collect.CollectPaymentInfo({
    //         paymentToken: address(throwingERC20),
    //         paymentType: Collect.PaymentType.ERC20,
    //         paymentAmount: 10,
    //         paymentRecipient: paymentRecipient
    //     });
    //     paymentParams = Collect.CollectPaymentParams({
    //         paymentToken: address(throwingERC20),
    //         paymentType: Collect.PaymentType.ERC20,
    //         paymentAmount: 10
    //     });
    //     ipAssetId = _createIpAsset(collector, 1, abi.encode(paymentInfo));
    //     vm.expectRevert(Errors.CollectPaymentModule_ERC20TransferInvalidReturnValue.selector);
    //     _collect(ipAssetId);
    // }

    // /// @notice Tests that ERC20 payments work as expected.
    // function test_CollectPaymentModuleERC20Collect() public parameterizePaymentInfo(paymentSuiteERC20()) {
    //     uint256 recipientStartingBalance = erc20.balanceOf(paymentRecipient);
    //     uint256 collectorStartingBalance = erc20.balanceOf(collector);
    //     paymentAmount = paymentParams.paymentAmount;
    //     _collect(ipAssetId);
    //     assertEq(erc20.balanceOf(paymentRecipient), recipientStartingBalance + paymentAmount);
    //     assertEq(erc20.balanceOf(collector), collectorStartingBalance - paymentAmount);
    // }

    // /// @notice Tests that payments without sufficient funds revert.
    // function test_CollectPaymentModuleInsufficientFunds() public {
    //     paymentInfo = Collect.CollectPaymentInfo({
    //         paymentToken: address(0),
    //         paymentType: Collect.PaymentType.NATIVE,
    //         paymentAmount: 10,
    //         paymentRecipient: paymentRecipient
    //     });
    //     paymentParams = Collect.CollectPaymentParams({
    //         paymentToken: address(0),
    //         paymentType: Collect.PaymentType.NATIVE,
    //         paymentAmount: 10
    //     });
    //     ipAssetId = _createIpAsset(alice, 1, abi.encode(paymentInfo));

    //     vm.prank(collector);
    //     vm.expectRevert(Errors.CollectPaymentModule_PaymentInsufficient.selector);
    //     collectModule.collect{value: 0}(Collect.CollectParams({
    //         ipAssetId: ipAssetId,
    //         collector: collector,
    //         collectData: abi.encode(paymentParams),
    //         collectNftInitData: "",
    //         collectNftData: ""
    //     }));
    // }

    /// @notice Returns a list of parameterized payment test cases.
    function paymentSuite() internal returns (CollectPaymentSet[] memory) {
        delete paymentSets;
        paymentSets.push(
            CollectPaymentSet(
                Collect.CollectPaymentInfo(address(0), Collect.PaymentType.NATIVE, 1 ether, alice),
                Collect.CollectPaymentParams(address(0), Collect.PaymentType.NATIVE, 1 ether)
            )
        );
        paymentSets.push(
            CollectPaymentSet(
                Collect.CollectPaymentInfo(address(erc20), Collect.PaymentType.ERC20, 10000, alice),
                Collect.CollectPaymentParams(address(erc20), Collect.PaymentType.ERC20, 10000)
            )
        );
        paymentSets.push(
            CollectPaymentSet(
                Collect.CollectPaymentInfo(address(weth), Collect.PaymentType.ERC20, 99, alice),
                Collect.CollectPaymentParams(address(weth), Collect.PaymentType.ERC20, 99)
            )
        );
        return paymentSets;
    }

    /// @notice Returns a list of parameterized native payment test cases.
    function paymentSuiteNative() internal returns (CollectPaymentSet[] memory) {
        delete paymentSets;
        paymentSets.push(
            CollectPaymentSet(
                Collect.CollectPaymentInfo(address(0), Collect.PaymentType.NATIVE, 1 ether, alice),
                Collect.CollectPaymentParams(address(0), Collect.PaymentType.NATIVE, 1 ether)
            )
        );
        paymentSets.push(
            CollectPaymentSet(
                Collect.CollectPaymentInfo(address(0), Collect.PaymentType.NATIVE, 99 ether, alice),
                Collect.CollectPaymentParams(address(0), Collect.PaymentType.NATIVE, 99 ether)
            )
        );
        return paymentSets;
    }

    /// @notice Returns a list of parameterized ERC20 payment test cases.
    function paymentSuiteERC20() internal returns (CollectPaymentSet[] memory) {
        delete paymentSets;
        paymentSets.push(
            CollectPaymentSet(
                Collect.CollectPaymentInfo(address(erc20), Collect.PaymentType.ERC20, 999, alice),
                Collect.CollectPaymentParams(address(erc20), Collect.PaymentType.ERC20, 999)
            )
        );
        return paymentSets;
    }

    /// @dev Helper function that initializes a collect module.
    /// @param collectNftImpl Collect NFT impl address used for collecting.
    function _initCollectModule(address collectNftImpl) internal virtual override {
        collectModule.initCollect(Collect.InitCollectParams({
            ipAssetId: ipAssetId,
            collectNftImpl: collectNftImpl,
            data: abi.encode(paymentInfo)
        }));
    }

    /// @dev Helper function that performs collect module collection.
    /// @param ipAssetId_ The id of the IP asset being collected.
    function _collect(uint256 ipAssetId_) internal virtual override returns (address, uint256) {
        vm.prank(collector);
        if (paymentParams.paymentType == Collect.PaymentType.NATIVE) {
            return collectModule.collect{value: paymentParams.paymentAmount}(Collect.CollectParams({
                ipAssetId: ipAssetId_,
                collector: collector,
                collectData: abi.encode(paymentParams),
                collectNftInitData: "",
                collectNftData: ""
            }));
        }
        return collectModule.collect(Collect.CollectParams({
            ipAssetId: ipAssetId_,
            collector: collector,
            collectData: abi.encode(paymentParams),
            collectNftInitData: "",
            collectNftData: ""
        }));
    }

    /// @notice Changes the base testing collect module deployment to deploy the 
    ///         mock payment collect module instead.
    function _deployCollectModule(address collectNftImpl) internal virtual override  returns (address) {
        collectModuleImpl = address(new MockCollectPaymentModule(address(registry), collectNftImpl));

        collectPaymentModule = ICollectPaymentModule(
            _deployUUPSProxy(
                    collectModuleImpl,
                    abi.encodeWithSelector(
                        bytes4(keccak256(bytes("initialize(address)"))), address(accessControl)
                    )
            )
        );

        return address(collectPaymentModule);
    }

}
