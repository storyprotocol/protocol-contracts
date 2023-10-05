// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {ERC20} from "solmate/src/tokens/ERC20.sol";

interface ISplitMain {
    error InvalidSplit__TooFewAccounts(uint256 accountsLength);

    function createSplit(
        address[] calldata accounts_,
        uint32[] calldata percentAllocations_,
        uint32 distributorFee_,
        address controller_
    ) external returns (address);

    function updateAndDistributeETH(
        address split_,
        address[] calldata accounts_,
        uint32[] calldata percentAllocations_,
        uint32 distributorFee_,
        address distributorAddress_
    ) external;

    function updateAndDistributeERC20(
        address split_,
        ERC20 token_,
        address[] calldata accounts_,
        uint32[] calldata percentAllocations_,
        uint32 distributorFee_,
        address distributorAddress_
    ) external;

    function getETHBalance(address account_) external view returns (uint256);

    function getERC20Balance(address account_, ERC20 token_) external view returns (uint256);

    function withdraw(address account_, uint256 withdrawETH_, ERC20[] calldata tokens_) external;
}
