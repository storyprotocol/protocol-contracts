// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { ITermsProcessor } from "./ITermsProcessor.sol";
import { BaseTermsProcessor } from "./BaseTermsProcessor.sol";
import { EmptyArray, LengthMismatch } from "contracts/errors/General.sol";

contract MultiTermsProcessor is BaseTermsProcessor {
    error TooManyTermsProcessors();

    event ProcessorsSet(ITermsProcessor[] processors);

    ITermsProcessor[] public processors;

    uint256 public constant MAX_PROCESSORS = 100;

    constructor(address authorizedExecutor, ITermsProcessor[] memory _processors) BaseTermsProcessor(authorizedExecutor) {
        _setProcessors(_processors);
    }

    function _setProcessors(ITermsProcessor[] memory _processors) private {
        if (_processors.length == 0) revert EmptyArray();
        if (_processors.length > MAX_PROCESSORS)
            revert TooManyTermsProcessors();
        processors = _processors;
        emit ProcessorsSet(_processors);
    }

    function _executeTerms(bytes calldata data) internal override returns (bytes memory newData) {
        uint256 length = processors.length;
        bytes[] memory encodedTerms = new bytes[](length);
        encodedTerms = abi.decode(data, (bytes[]));
        bytes[] memory newEncodedTerms = new bytes[](length);
        for (uint256 i = 0; i < length;) {
            newEncodedTerms[i] = processors[i].executeTerms(encodedTerms[i]);
            unchecked {
                i++;
            }
        }
        return abi.encode(newEncodedTerms);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override returns (bool) {
        bool supported = true;
        if (interfaceId == type(ITermsProcessor).interfaceId) {
            uint256 length = processors.length;
            for (uint256 i = 0; i < length;) {
                supported && processors[i].supportsInterface(interfaceId);
                unchecked {
                    i++;
                }
            }
            return supported;
        }
        return super.supportsInterface(interfaceId);
    }

    function tersmExecutedSuccessfully(bytes calldata data) external view override returns (bool) {
        uint256 length = processors.length;
        bytes[] memory encodedTerms = new bytes[](length);
        encodedTerms = abi.decode(data, (bytes[]));
        bool result = true;
        for (uint256 i = 0; i < length;) {
            result = result && processors[i].tersmExecutedSuccessfully(encodedTerms[i]);
            unchecked {
                i++;
            }
        }
        return result;
    }

}