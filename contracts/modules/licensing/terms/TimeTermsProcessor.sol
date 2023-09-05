// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { BaseTermsProcessor } from "./BaseTermsProcessor.sol";
import { LibDuration } from "../../timing/LibDuration.sol";

contract TimeTermsProcessor is BaseTermsProcessor {
    using LibDuration for LibDuration.TimeConfig;

    constructor(address authorizedExecutor) BaseTermsProcessor(authorizedExecutor) {}

    function _executeTerms(bytes calldata data) internal virtual override returns (bytes memory newData) {
        LibDuration.TimeConfig memory config = abi.decode(data, (LibDuration.TimeConfig));
        if (config.startTime == LibDuration.START_TIME_NOT_SET) {
            config.startTime = uint64(block.timestamp);
        }
        return abi.encode(config);
    }

    function tersmExecutedSuccessfully(bytes calldata data) external view override returns (bool) {
        LibDuration.TimeConfig memory config = abi.decode(data, (LibDuration.TimeConfig));
        return config.isActive();
    }

}