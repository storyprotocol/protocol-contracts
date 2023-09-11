// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { ITermsProcessor } from "./ITermsProcessor.sol";
import { ZeroAddress, Unauthorized } from "contracts/errors/General.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";


/**
 * @title BaseTermsProcessor
 * @notice Base contract for licensing terms processors, which encode, decode and execute the terms set on an IERC5218 license parameters,
 * in particular the TermsProcessorConfig struct for the terms parameter in createLicense().
 * TermsProcessors need to be deployed once per AUTHORIZED_EXECUTOR, which is usually each Franchise IPAssetRegistry.
 * @dev TermsProcessor are intended to be reused accross the protocol, so they should be generic enough to be used by different modules.
 * Most will be stateless, and if a terms processor needs to update something license specific,
 * it should return the updated encoded data in executeTerms() so it is stored back on the license.
 * There could be cases where other methods or state is needed for more complicated flows.
 */
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

    /// @inheritdoc ITermsProcessor
    function executeTerms(bytes calldata data) onlyAuthorizedExecutor external returns(bytes memory newData) {
        return _executeTerms(data);
    }

    /// method defining the actual execution of the terms, with no access control for caller, to be implemented by the child contract
    function _executeTerms(bytes calldata data) internal virtual returns (bytes memory newData);

    
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(ITermsProcessor).interfaceId || super.supportsInterface(interfaceId);
    }

}