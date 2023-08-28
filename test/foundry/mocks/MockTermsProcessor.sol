// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "contracts/modules/licensing/terms/ITermsProcessor.sol";

contract MockTermsProcessor is ITermsProcessor {

    bool success = true;

    function setSuccess(bool value) external {
        success = value;
    }

    function supportsInterface(
        bytes4
    ) external pure override returns (bool) {
        return true;
    }

    function executeTerms(
        bytes calldata data
    ) external pure override returns (bytes memory newData) {
        return data;
    }

    function tersmExecutedSuccessfully(
        bytes calldata
    ) external view override returns (bool) {
        return success;
    }
}