// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "contracts/interfaces/modules/royalties/ISplitMain.sol";
import "./MockSplit.sol";
import "test/foundry/mocks/MockERC20.sol";

contract MockSplitMain is ISplitMain {

    mapping(ERC20 => mapping(address => uint256)) internal erc20Balances;
    uint public TOTAL_SUPPLY = 1e6;

    constructor() {}

    function createSplit(
        address[] calldata,
        uint32[] calldata,
        uint32,
        address
    ) external override returns (address) {
        return address(new MockSplit());
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
        address split,
        ERC20 token,
        address[] calldata accounts,
        uint32[] calldata percentAllocations,
        uint32,
        address
    ) external override {
        // simulate SplitMain behavior that SplitMain reserve 1 from split balance
        uint balance = token.balanceOf(split) - 1;
        MockSplit(split).sendERC20ToMain(token, balance);
        for (uint i = 0; i < accounts.length; i++) {
            erc20Balances[token][accounts[i]] = percentAllocations[i] * balance / TOTAL_SUPPLY;
        }
    }

    function getETHBalance(address) external pure override returns (uint256) {
        return 100;
    }

    function getERC20Balance(address account, ERC20 token) external view override returns (uint256) {
        return erc20Balances[token][account];
    }

    function withdraw(address account, uint256 withdrawETH, ERC20[] calldata tokens) external override {
        if (withdrawETH != 0) {
            revert("Unsupport ETH");
        }
        unchecked {
            for (uint256 i = 0; i < tokens.length; ++i) {
                // Simulate SplitMain behavior that account balance reserve 1
                uint256 withdrawn = erc20Balances[tokens[i]][account] - 1;
                erc20Balances[tokens[i]][account] = 1;
                tokens[i].transfer(account, withdrawn);
            }
        }
    }
}
