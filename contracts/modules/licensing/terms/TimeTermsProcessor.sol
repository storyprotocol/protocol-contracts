// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { ITermsProcessor } from "./ITermsProcessor.sol";
import { LibDuration } from "../../timing/LibDuration.sol";

contract TimeTermsProcessor is ITermsProcessor {
    using LibDuration for LibDuration.TimeConfig;

    function executeTerms(bytes calldata data) external view override returns (bytes memory newData) {
        // TODO: check caller is the rights manager
        LibDuration.TimeConfig memory config = abi.decode(data, (LibDuration.TimeConfig));
        if (config.startTime == 0) {
            config.startTime = uint64(block.timestamp);
        }
        return abi.encode(config);
    }

    function tersmExecutedSuccessfully(bytes calldata data) external view override returns (bool) {
        LibDuration.TimeConfig memory config = abi.decode(data, (LibDuration.TimeConfig));
        return config.isActive();
    }

    function supportsInterface(
        bytes4 interfaceId
    ) external pure override returns (bool) {
        return interfaceId == type(ITermsProcessor).interfaceId;
    }
}