// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

interface IRoyaltyPolicy {
    function initPolicy(address account, bytes calldata data) external;
    function updateDistribution(address account, bytes calldata data) external;
    function distribute(address account, address token) external;
}