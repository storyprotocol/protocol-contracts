// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { ITermsProcessor } from "contracts/interfaces/modules/licensing/terms/ITermsProcessor.sol";
import { BaseTermsProcessor } from "./BaseTermsProcessor.sol";
import { EmptyArray, LengthMismatch } from "contracts/errors/General.sol";


/// NOTE: this contract is not tested yet, do not use.
/// @title MultiTermsProcessor
/// @author Raul Martinez
/// @notice Contract that allow to compose multiple terms processors into one, to allow for complex license arrangements.
/// Either all processors are executed successfully, or none are.
contract MultiTermsProcessor is BaseTermsProcessor {
    error TooManyTermsProcessors();

    event ProcessorsSet(ITermsProcessor[] processors);

    ITermsProcessor[] public processors;

    /// arbitrary limit to avoid gas limit issues. If the processors are complex, gas DOS might be reached anyway.
    uint256 public constant MAX_PROCESSORS = 50;

    constructor(address authorizedExecutor_, ITermsProcessor[] memory processors_) BaseTermsProcessor(authorizedExecutor_) {
        _setProcessors(processors_);
    }

    /// Sets the processors to be executed in order.
    function _setProcessors(ITermsProcessor[] memory processors_) private {
        if (processors_.length == 0) revert EmptyArray();
        if (processors_.length > MAX_PROCESSORS)
            revert TooManyTermsProcessors();
        processors = processors_;
        emit ProcessorsSet(processors_);
    }

    
    /// Decode the data into an array of bytes with length == processors length, and execute each processor in order.
    /// Encode the results into a new array of bytes and return it.
    /// @param data_ must be decodable into an array of bytes with length == processors length.
    /// @return newData the encoded bytes array with the results of each processor execution.
    function _executeTerms(bytes calldata data_) internal override returns (bytes memory newData) {
        uint256 length = processors.length;
        bytes[] memory encodedTerms = new bytes[](length);
        encodedTerms = abi.decode(data_, (bytes[]));
        bytes[] memory newEncodedTerms = new bytes[](length);
        for (uint256 i = 0; i < length;) {
            newEncodedTerms[i] = processors[i].executeTerms(encodedTerms[i]);
            unchecked {
                i++;
            }
        }
        return abi.encode(newEncodedTerms);
    }

    /// ERC165 interface support, but for ITermsProcessor it only returns true if only all processors support the interface.
    function supportsInterface(
        bytes4 interfaceId_
    ) public view override returns (bool) {
        bool supported = true;
        if (interfaceId_ == type(ITermsProcessor).interfaceId) {
            uint256 length = processors.length;
            for (uint256 i = 0; i < length;) {
                supported && processors[i].supportsInterface(interfaceId_);
                unchecked {
                    i++;
                }
            }
            return supported;
        }
        return super.supportsInterface(interfaceId_);
    }

    /// Checks if all the terms are executed, in order. If one fails, it returns false.
    function termsExecutedSuccessfully(bytes calldata data_) external view override returns (bool) {
        uint256 length = processors.length;
        bytes[] memory encodedTerms = new bytes[](length);
        encodedTerms = abi.decode(data_, (bytes[]));
        bool result = true;
        for (uint256 i = 0; i < length;) {
            result = result && processors[i].termsExecutedSuccessfully(encodedTerms[i]);
            unchecked {
                i++;
            }
        }
        return result;
    }

}