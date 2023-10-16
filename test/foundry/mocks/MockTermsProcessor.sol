// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "contracts/interfaces/modules/licensing/terms/ITermsProcessor.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";


contract MockTermsProcessor is ITermsProcessor, ERC165 {

    bool private _success = true;

    function setSuccess(bool value) external {
        _success = value;
    }

    function supportsInterface(
        bytes4
    ) public pure override(ERC165, IERC165) returns (bool) {
        return true;
    }

    function executeTerms(
        bytes calldata data
    ) external pure override returns (bytes memory newData) {
        return data;
    }

    function termsExecutedSuccessfully(
        bytes calldata
    ) external view override returns (bool) {
        return _success;
    }
}