// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { BaseTermsProcessor } from "./BaseTermsProcessor.sol";
import { LibDuration } from "../../timing/LibDuration.sol";


/// @title TimeTermsProcessor
/// @author Raul Martinez
/// @notice Processor to set time limits to Licenses up to a Time To Live (TTL). It has 2 modes of operation:
/// 1- Timer starts on a specific date set on License creation, and ends after a certain amount of time.
/// To do this, set startTime to a timestemp when encoding the terms in createLicense().
/// 2- Timer starts on License execution, and ends after a certain amount of time.
/// To do this, set startTime to LibDuration.START_TIME_NOT_SET (0) when encoding the terms in createLicense().
/// The processor will set the startTime to the block.timestamp when the terms are executed.
/// Use case for this would be to indicate "this license is valid within 1 year after the first time it is used"
contract TimeTermsProcessor is BaseTermsProcessor {
    using LibDuration for LibDuration.TimeConfig;

    constructor(address authorizedExecutor) BaseTermsProcessor(authorizedExecutor) {}

    /// If startTime is not set, set it to block.timestamp and return the new encoded data. If startTime is set, return the same data.
    function _executeTerms(bytes calldata data) internal virtual override returns (bytes memory newData) {
        LibDuration.TimeConfig memory config = abi.decode(data, (LibDuration.TimeConfig));
        if (config.startTime == LibDuration.START_TIME_NOT_SET) {
            config.startTime = uint64(block.timestamp);
        }
        return abi.encode(config);
    }

    /// returns true if the current block.timestamp is within the start and start + ttl, false otherwise
    function termsExecutedSuccessfully(bytes calldata data) external view override returns (bool) {
        LibDuration.TimeConfig memory config = abi.decode(data, (LibDuration.TimeConfig));
        return config.isActive();
    }

}