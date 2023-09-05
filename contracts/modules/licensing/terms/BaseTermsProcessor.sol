// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { ITermsProcessor } from "./ITermsProcessor.sol";
import { ZeroAddress, Unauthorized } from "contracts/errors/General.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract BaseTermsProcessor is ITermsProcessor, ERC165 {

    address public immutable AUTHORIZED_EXECUTOR;

    constructor(address authorizedExecutor) {
        if (authorizedExecutor == address(0)) {
            revert ZeroAddress();
        }
        AUTHORIZED_EXECUTOR = authorizedExecutor;
    }

    modifier onlyAuthorizedExecutor() {
        if(msg.sender != AUTHORIZED_EXECUTOR) revert Unauthorized();
        _;
    }

    function executeTerms(bytes calldata data) onlyAuthorizedExecutor external returns(bytes memory newData) {
        return _executeTerms(data);
    }

    function _executeTerms(bytes calldata data) internal virtual returns (bytes memory newData);

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(ITermsProcessor).interfaceId || super.supportsInterface(interfaceId);
    }

}