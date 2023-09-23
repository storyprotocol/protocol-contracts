// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ICollectPaymentModuleEventsAndErrors } from "contracts/interfaces/ICollectPaymentModuleEventsAndErrors.sol";
import { ICollectModule } from "contracts/interfaces/ICollectModule.sol";
import { ICollectPaymentModule } from "contracts/interfaces/ICollectPaymentModule.sol";
import { ICollectNFT } from "contracts/interfaces/ICollectNFT.sol";
import { PaymentType } from "contracts/lib/CollectPaymentModuleEnums.sol";

import { BaseCollectModuleTest } from "./BaseCollectModuleTest.sol";
import { BaseTest } from "test/foundry/utils/BaseTest.sol";
import { MockCollectPaymentModule } from "test/foundry/mocks/MockCollectPaymentModule.sol";
import { MockNativeTokenNonReceiver } from "test/foundry/mocks/MockNativeTokenNonReceiver.sol";
import { MockThrowingERC20 } from "test/foundry/mocks/MockThrowingERC20.sol";
import { MockCollectNFT } from "test/foundry/mocks/MockCollectNFT.sol";
import { MockERC20 } from "test/foundry/mocks/MockERC20.sol";
import { MockWETH } from "test/foundry/mocks/MockWETH.sol";

import { InitCollectParams, CollectParams } from "contracts/lib/CollectModuleStructs.sol";
import {CollectPaymentInfo, CollectPaymentParams} from "contracts/lib/CollectPaymentModuleStructs.sol";

/// @title Collect Payment Module Base Testing Contract
/// @notice Tests all functionality provided by the base payment collect module.
contract CollectPaymentModuleBaseTest is BaseCollectModuleTest, ICollectPaymentModuleEventsAndErrors {

    ICollectPaymentModule collectPaymentModule;

    MockERC20 public erc20;
    MockWETH public weth;

    address paymentToken;
    PaymentType paymentType;
    uint256 paymentAmount;
    address payable paymentRecipient;
    CollectPaymentInfo paymentInfo;
    CollectPaymentParams paymentParams;

    CollectPaymentSet[] paymentSets;

    struct CollectPaymentSet {
        CollectPaymentInfo info;
        CollectPaymentParams params;
    }

    modifier parameterizePaymentInfo(CollectPaymentSet[] memory paymentInfoSuite) {
        uint256 length = paymentInfoSuite.length;
        for (uint256 i = 0; i < length; ) {
            paymentInfo = paymentInfoSuite[i].info;
            paymentParams = paymentInfoSuite[i].params;
            ipAssetId = _createIPAsset(alice, 1, abi.encode(paymentInfo));
            _;
            i += 1;
        }
    }

    /// @notice Modifier that creates an IP asset for normal collect testing.
    /// @param ipAssetOwner The owner address for the new IP asset.
    /// @param ipAssetType The type of the IP asset being created.
    /// TODO: Refactor to make better use of test parameterization.
    modifier createIPAsset(address ipAssetOwner, uint8 ipAssetType) override {
        ipAssetId = _createIPAsset(ipAssetOwner, ipAssetType, abi.encode(paymentInfo));
        _;
    }

    /// @notice Sets up testing for the base collect payment module.
    function setUp() public virtual override(BaseCollectModuleTest) { 
        super.setUp();
        paymentToken = address(0);
        paymentType =  PaymentType.NATIVE;
        paymentAmount =  1 ether;
        paymentRecipient = alice;
        collector = cal;
        vm.deal(collector, 999 ether);
        paymentInfo = CollectPaymentInfo({
            paymentToken: paymentToken,
            paymentType: paymentType,
            paymentAmount: paymentAmount,
            paymentRecipient: paymentRecipient
        });
        paymentParams = CollectPaymentParams({
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

    /// @notice Tests that the collect payment module is correctly initialized.
    function test_CollectPaymentModuleInit() public parameterizePaymentInfo(paymentSuite()) {
        CollectPaymentInfo memory p = collectPaymentModule.getPaymentInfo(franchiseId, ipAssetId);
        assertEq(p.paymentToken, paymentInfo.paymentToken);
        assertEq(uint8(p.paymentType), uint8(paymentInfo.paymentType));
        assertEq(p.paymentAmount, paymentInfo.paymentAmount);
        assertEq(p.paymentRecipient, paymentInfo.paymentRecipient);
    }

    function test_CollectPaymentModuleZeroPaymentReverts() public {

        vm.prank(address(ipAssetRegistry));
        paymentInfo = CollectPaymentInfo(address(0), PaymentType.NATIVE, 0 ether, alice);
        vm.expectRevert(CollectPaymentModuleAmountInvalid.selector);
        _initCollectModule(franchiseId, defaultCollectNFTImpl);
    }

    function test_CollectPaymentModuleInvalidSettingsReverts() public {

        vm.prank(address(ipAssetRegistry));
        paymentInfo = CollectPaymentInfo(address(erc20), PaymentType.NATIVE, 1 ether, alice);
        vm.expectRevert(CollectPaymentModuleInvalidSettings.selector);
        _initCollectModule(franchiseId, defaultCollectNFTImpl);
    }

    function test_CollectPaymentModuleInvalidTokenReverts() public {

        vm.prank(address(ipAssetRegistry));
        paymentInfo = CollectPaymentInfo(bob, PaymentType.ERC20, 1 ether, alice);
        vm.expectRevert(CollectPaymentModuleTokenInvalid.selector);
        _initCollectModule(franchiseId, defaultCollectNFTImpl);
    }

    function test_CollectPaymentModuleNativeCollect() public parameterizePaymentInfo(paymentSuiteNative()) {
        uint256 recipientStartingBalance = paymentRecipient.balance;
        uint256 collectorStartingBalance = collector.balance;
        paymentAmount = paymentParams.paymentAmount;
        _collect(franchiseId, ipAssetId);
        assertEq(collector.balance, collectorStartingBalance - paymentAmount);
        assertEq(paymentRecipient.balance, recipientStartingBalance + paymentAmount);
    }

    function test_CollectPaymentModuleNativeTransferFailReverts() public {
        address payable throwingReceiver  = payable(address(new MockNativeTokenNonReceiver()));

        paymentInfo = CollectPaymentInfo({
            paymentToken: address(0),
            paymentType: PaymentType.NATIVE,
            paymentAmount: 10,
            paymentRecipient: throwingReceiver
        });
        paymentParams = CollectPaymentParams({
            paymentToken: address(0),
            paymentType: PaymentType.NATIVE,
            paymentAmount: 10
        });
        ipAssetId = _createIPAsset(collector, 1, abi.encode(paymentInfo));

        vm.prank(collector);
        vm.expectRevert(CollectPaymentModuleNativeTransferFailed.selector);
        collectModule.collect{value: 10}(CollectParams({
            franchiseId: franchiseId,
            ipAssetId: ipAssetId,
            collector: collector,
            collectData: abi.encode(paymentParams),
            collectNFTInitData: "",
            collectNFTData: ""
        }));
    }

    function test_CollectPaymentModuleInvalidPaymentParamsReverts() public {
        paymentInfo = CollectPaymentInfo({
            paymentToken: address(erc20),
            paymentType: PaymentType.ERC20,
            paymentAmount: 10,
            paymentRecipient: paymentRecipient
        });
        paymentParams = CollectPaymentParams({
            paymentToken: address(erc20),
            paymentType: PaymentType.ERC20,
            paymentAmount: 1
        });
        ipAssetId = _createIPAsset(collector, 1, abi.encode(paymentInfo));
        vm.expectRevert(CollectPaymentModulePaymentParamsInvalid.selector);
        _collect(franchiseId, ipAssetId);
    }

    function test_CollectPaymentModuleERC20TransferFailReverts() public {
        MockThrowingERC20 throwingERC20 = new MockThrowingERC20("Story Protocol Mock Token", "SP", 18, MockThrowingERC20.TransferBehavior.Fail);
        vm.prank(collector);
        throwingERC20.mint(999999);
        paymentInfo = CollectPaymentInfo({
            paymentToken: address(throwingERC20),
            paymentType: PaymentType.ERC20,
            paymentAmount: 10,
            paymentRecipient: paymentRecipient
        });
        paymentParams = CollectPaymentParams({
            paymentToken: address(throwingERC20),
            paymentType: PaymentType.ERC20,
            paymentAmount: 10
        });
        ipAssetId = _createIPAsset(collector, 1, abi.encode(paymentInfo));
        vm.expectRevert(CollectPaymentModuleERC20TransferFailed.selector);
        _collect(franchiseId, ipAssetId);
    }

    function test_CollectPaymentModuleERC20InvalidPaymentReverts() public {
        paymentInfo = CollectPaymentInfo({
            paymentToken: address(erc20),
            paymentType: PaymentType.ERC20,
            paymentAmount: 10,
            paymentRecipient: paymentRecipient
        });
        paymentParams = CollectPaymentParams({
            paymentToken: address(erc20),
            paymentType: PaymentType.ERC20,
            paymentAmount: 10
        });
        ipAssetId = _createIPAsset(collector, 1, abi.encode(paymentInfo));
        vm.expectRevert(CollectPaymentModuleNativeTokenNotAllowed.selector);
        collectModule.collect{value: 10}(CollectParams({
            franchiseId: franchiseId,
            ipAssetId: ipAssetId,
            collector: collector,
            collectData: abi.encode(paymentParams),
            collectNFTInitData: "",
            collectNFTData: ""
        }));
    }

    function test_CollectPaymentModuleERC20InsufficientFundsReverts() public {
        paymentInfo = CollectPaymentInfo({
            paymentToken: address(erc20),
            paymentType: PaymentType.ERC20,
            paymentAmount: 9999999,
            paymentRecipient: paymentRecipient
        });
        paymentParams = CollectPaymentParams({
            paymentToken: address(erc20),
            paymentType: PaymentType.ERC20,
            paymentAmount: 9999999
        });
        ipAssetId = _createIPAsset(collector, 1, abi.encode(paymentInfo));
        vm.expectRevert(CollectPaymentModulePaymentInsufficient.selector);
        _collect(franchiseId, ipAssetId);

    }

    function test_CollectPaymentModuleERC20TransferInvalidABIReverts() public {
        MockThrowingERC20 throwingERC20 = new MockThrowingERC20("Story Protocol Mock Token", "SP", 18, MockThrowingERC20.TransferBehavior.ReturnInvalidABI);
        vm.prank(collector);
        throwingERC20.mint(999999);
        paymentInfo = CollectPaymentInfo({
            paymentToken: address(throwingERC20),
            paymentType: PaymentType.ERC20,
            paymentAmount: 10,
            paymentRecipient: paymentRecipient
        });
        paymentParams = CollectPaymentParams({
            paymentToken: address(throwingERC20),
            paymentType: PaymentType.ERC20,
            paymentAmount: 10
        });
        ipAssetId = _createIPAsset(collector, 1, abi.encode(paymentInfo));
        vm.expectRevert(CollectPaymentModuleERC20TransferInvalidABIEncoding.selector);
        _collect(franchiseId, ipAssetId);
    }

    function test_CollectPaymentModuleERC20TransferInvalidReturnReverts() public {
        MockThrowingERC20 throwingERC20 = new MockThrowingERC20("Story Protocol Mock Token", "SP", 18, MockThrowingERC20.TransferBehavior.ReturnFalse);
        vm.prank(collector);
        throwingERC20.mint(999999);
        paymentInfo = CollectPaymentInfo({
            paymentToken: address(throwingERC20),
            paymentType: PaymentType.ERC20,
            paymentAmount: 10,
            paymentRecipient: paymentRecipient
        });
        paymentParams = CollectPaymentParams({
            paymentToken: address(throwingERC20),
            paymentType: PaymentType.ERC20,
            paymentAmount: 10
        });
        ipAssetId = _createIPAsset(collector, 1, abi.encode(paymentInfo));
        vm.expectRevert(CollectPaymentModuleERC20TransferInvalidReturnValue.selector);
        _collect(franchiseId, ipAssetId);
    }

    function test_CollectPaymentModuleERC20Collect() public parameterizePaymentInfo(paymentSuiteERC20()) {
        uint256 recipientStartingBalance = erc20.balanceOf(paymentRecipient);
        uint256 collectorStartingBalance = erc20.balanceOf(collector);
        paymentAmount = paymentParams.paymentAmount;
        _collect(franchiseId, ipAssetId);
        assertEq(erc20.balanceOf(paymentRecipient), recipientStartingBalance + paymentAmount);
        assertEq(erc20.balanceOf(collector), collectorStartingBalance - paymentAmount);
    }

    function test_CollectPaymentModuleInsufficientFunds() public {
        paymentInfo = CollectPaymentInfo({
            paymentToken: address(0),
            paymentType: PaymentType.NATIVE,
            paymentAmount: 10,
            paymentRecipient: paymentRecipient
        });
        paymentParams = CollectPaymentParams({
            paymentToken: address(0),
            paymentType: PaymentType.NATIVE,
            paymentAmount: 10
        });
        ipAssetId = _createIPAsset(alice, 1, abi.encode(paymentInfo));

        vm.prank(collector);
        vm.expectRevert(CollectPaymentModulePaymentInsufficient.selector);
        collectModule.collect{value: 0}(CollectParams({
            franchiseId: franchiseId,
            ipAssetId: ipAssetId,
            collector: collector,
            collectData: abi.encode(paymentParams),
            collectNFTInitData: "",
            collectNFTData: ""
        }));
    }

    /// @notice Returns a list of collect payment infos for test parameterization.
    function paymentSuite() internal returns (CollectPaymentSet[] memory) {
        delete paymentSets;
        paymentSets.push(
            CollectPaymentSet(
                CollectPaymentInfo(address(0), PaymentType.NATIVE, 1 ether, alice),
                CollectPaymentParams(address(0), PaymentType.NATIVE, 1 ether)
            )
        );
        paymentSets.push(
            CollectPaymentSet(
                CollectPaymentInfo(address(erc20), PaymentType.ERC20, 10000, alice),
                CollectPaymentParams(address(erc20), PaymentType.ERC20, 10000)
            )
        );
        paymentSets.push(
            CollectPaymentSet(
                CollectPaymentInfo(address(weth), PaymentType.ERC20, 99, alice),
                CollectPaymentParams(address(weth), PaymentType.ERC20, 99)
            )
        );
        return paymentSets;
    }

    /// @notice Returns a list of collect payment infos for test parameterization.
    function paymentSuiteNative() internal returns (CollectPaymentSet[] memory) {
        delete paymentSets;
        paymentSets.push(
            CollectPaymentSet(
                CollectPaymentInfo(address(0), PaymentType.NATIVE, 1 ether, alice),
                CollectPaymentParams(address(0), PaymentType.NATIVE, 1 ether)
            )
        );
        paymentSets.push(
            CollectPaymentSet(
                CollectPaymentInfo(address(0), PaymentType.NATIVE, 99 ether, alice),
                CollectPaymentParams(address(0), PaymentType.NATIVE, 99 ether)
            )
        );
        return paymentSets;
    }

    /// @notice Returns a list of collect payment infos for test parameterization.
    function paymentSuiteERC20() internal returns (CollectPaymentSet[] memory) {
        delete paymentSets;
        paymentSets.push(
            CollectPaymentSet(
                CollectPaymentInfo(address(erc20), PaymentType.ERC20, 999, alice),
                CollectPaymentParams(address(erc20), PaymentType.ERC20, 999)
            )
        );
        return paymentSets;
    }

    /// @dev Helper function that initializes a collect module.
    /// @param franchiseId The id of the franchise associated with the module.
    /// @param collectNFTImpl Collect NFT impl address used for collecting.
    function _initCollectModule(uint256 franchiseId, address collectNFTImpl) internal virtual override {
        collectModule.initCollect(InitCollectParams({
            franchiseId: franchiseId,
            ipAssetId: ipAssetId,
            collectNFTImpl: collectNFTImpl,
            data: abi.encode(paymentInfo)
        }));
    }

    /// @dev Helper function that performs collect module collection.
    /// @param franchiseId The id of the franchise of the IP asset.
    /// @param ipAssetId_ The id of the IP asset being collected.
    function _collect(uint256 franchiseId, uint256 ipAssetId_) internal virtual override returns (address, uint256) {
        vm.prank(collector);
        if (paymentParams.paymentType == PaymentType.NATIVE) {
            return collectModule.collect{value: paymentParams.paymentAmount}(CollectParams({
                franchiseId: franchiseId,
                ipAssetId: ipAssetId_,
                collector: collector,
                collectData: abi.encode(paymentParams),
                collectNFTInitData: "",
                collectNFTData: ""
            }));
        }
        return collectModule.collect(CollectParams({
            franchiseId: franchiseId,
            ipAssetId: ipAssetId_,
            collector: collector,
            collectData: abi.encode(paymentParams),
            collectNFTInitData: "",
            collectNFTData: ""
        }));
    }

    /// @notice Changes the base testing collect module deployment to deploy the 
    ///         mock payment collect module instead.
    function _deployCollectModule(address collectNFTImpl) internal virtual override  returns (address) {
        collectModuleImpl = address(new MockCollectPaymentModule(address(franchiseRegistry), collectNFTImpl));

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
