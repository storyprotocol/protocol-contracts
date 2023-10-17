// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { BaseTermsProcessor } from "./BaseTermsProcessor.sol";
import { IRoyaltyDistributor } from "contracts/modules/royalties/IRoyaltyDistributor.sol";
import { IIPAccountRegistry } from "contracts/ip-accounts/IIPAccountRegistry.sol";
import { IRoyaltyProportionPolicy } from "contracts/modules/royalties/policies/IRoyaltyProportionPolicy.sol";
import { EmptyArray, LengthMismatch } from "contracts/errors/General.sol";

struct RoyaltyTermsConfig {
    address payerNftContract;
    uint256 payerTokenId;
    address[] accounts;
    uint32[] allocationPercentages;
    bool isExecuted;
}


/// @title RoyaltyTermsProcessor
/// @notice Processor to set royalty split plan for Licensee.
/// the percentage of income from licensee will pay back to the licensor
contract RoyaltyTermsProcessor is BaseTermsProcessor {
    IRoyaltyDistributor public immutable ROYALTY_DISTRIBUTOR;

    constructor(address authorizedExecutor, address royaltyDistributor) BaseTermsProcessor(authorizedExecutor) {
        ROYALTY_DISTRIBUTOR = IRoyaltyDistributor(royaltyDistributor);
    }

    /// @dev Parse license terms and translate license terms into Royalty split
    function _executeTerms(bytes calldata data) internal virtual override returns (bytes memory newData) {
        RoyaltyTermsConfig memory config = abi.decode(data, (RoyaltyTermsConfig));
        if (config.accounts.length == 0) {
            revert EmptyArray();
        }

        if (config.accounts.length != config.allocationPercentages.length) {
            revert LengthMismatch();
        }
        IRoyaltyProportionPolicy.ProportionData memory policyData = IRoyaltyProportionPolicy.ProportionData({
            accounts: config.accounts,
            percentAllocations: config.allocationPercentages
        });
        ROYALTY_DISTRIBUTOR.updateDistribution(config.payerNftContract, config.payerTokenId, abi.encode(policyData));

        RoyaltyTermsConfig memory newConfig = RoyaltyTermsConfig({
            payerNftContract: config.payerNftContract,
            payerTokenId: config.payerTokenId,
            accounts: config.accounts,
            allocationPercentages: config.allocationPercentages,
            isExecuted: true
        });

        newData = abi.encode(newConfig);
    }

    /// @dev Return true if the terms exec executed with any errors.
    function termsExecutedSuccessfully(bytes calldata data) external pure override returns (bool) {
        RoyaltyTermsConfig memory config = abi.decode(data, (RoyaltyTermsConfig));
        return config.isExecuted;
    }
}