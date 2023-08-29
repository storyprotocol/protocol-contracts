// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { ITermsProcessor } from "./ITermsProcessor.sol";
import { LibDuration } from "../../timing/LibDuration.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract TimeTermsProcessor is ITermsProcessor, ERC165 {
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
    ) public view override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(ITermsProcessor).interfaceId || super.supportsInterface(interfaceId);
    }
}