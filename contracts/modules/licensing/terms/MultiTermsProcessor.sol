// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { ITermsProcessor } from "./ITermsProcessor.sol";
import { EmptyArray, LengthMismatch } from "contracts/errors/General.sol";

contract MultiTermsProcessor is ITermsProcessor {
    error TooManyTermsProcessors();

    event ProcessorsSet(ITermsProcessor[] processors);

    ITermsProcessor[] public processors;

    uint256 public constant MAX_PROCESSORS = 100;

    constructor(ITermsProcessor[] memory _processors) {
        setProcessors(_processors);
    }

    function setProcessors(ITermsProcessor[] memory _processors) public {
        if (_processors.length == 0) revert EmptyArray();
        if (_processors.length > MAX_PROCESSORS)
            revert TooManyTermsProcessors();
        processors = _processors;
        emit ProcessorsSet(_processors);
    }

    function executeTerms(bytes calldata data) external override returns (bool) {
        uint256 length = processors.length;
        bytes[] memory encodedTerms = new bytes[](length);
        encodedTerms = abi.decode(data, (bytes[]));
        bool result = true;
        for (uint256 i = 0; i < length;) {
            result = result && processors[i].executeTerms(encodedTerms[i]);
            unchecked {
                i++;
            }
        }
        return result;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) external view override returns (bool) {
        bool supported = true;
        if (interfaceId == type(ITermsProcessor).interfaceId) {
            uint256 length = processors.length;
            for (uint256 i = 0; i < length; i++) {
                supported && processors[i].supportsInterface(interfaceId);
            }
            return supported;
        }
        return false;
    }

    function tersmExecutedSuccessfully() external view override returns (bool) {
        uint256 length = processors.length;
        bool result = true;
        for (uint256 i = 0; i < length; i++) {
            result = result && processors[i].tersmExecutedSuccessfully();
        }
        return result;
    }

}