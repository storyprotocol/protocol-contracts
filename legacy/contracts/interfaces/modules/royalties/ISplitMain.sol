// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { ERC20 } from "solmate/src/tokens/ERC20.sol";

interface ISplitMain {

    function createSplit(
        address[] calldata accounts,
        uint32[] calldata percentAllocations,
        uint32 distributorFee,
        address controller
    ) external returns (address);

    function updateAndDistributeETH(
        address split,
        address[] calldata accounts,
        uint32[] calldata percentAllocations,
        uint32 distributorFee,
        address distributorAddress
    ) external;

    function updateAndDistributeERC20(
        address split,
        ERC20 token,
        address[] calldata accounts,
        uint32[] calldata percentAllocations,
        uint32 distributorFee,
        address distributorAddress
    ) external;

    function withdraw(address account, uint256 withdrawETH, ERC20[] calldata tokens) external;

    function getETHBalance(address account) external view returns (uint256);

    function getERC20Balance(address account, ERC20 token) external view returns (uint256);
}
