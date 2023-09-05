// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "contracts/modules/royalties/ISplitMain.sol";

contract MockSplitMain is ISplitMain {
    constructor() {}

    function createSplit(
        address[] calldata,
        uint32[] calldata,
        uint32,
        address
    ) external override pure returns (address) {
        return address(100);
    }

    function updateAndDistributeETH(
        address,
        address[] calldata,
        uint32[] calldata,
        uint32,
        address
    ) external override {

    }

    function updateAndDistributeERC20(
        address,
        ERC20,
        address[] calldata,
        uint32[] calldata,
        uint32,
        address
    ) external override {

    }

    function getETHBalance(address) external pure override returns (uint256) {
        return 100;
    }

    function getERC20Balance(address, ERC20) external pure override returns (uint256) {
        return 100;
    }

    function withdraw(address, uint256, ERC20[] calldata) external override {

    }
}
