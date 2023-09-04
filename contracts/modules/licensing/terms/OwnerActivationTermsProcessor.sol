// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { ITermsProcessor } from "./ITermsProcessor.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract OwnerActivationTermsProcessor is ITermsProcessor, ERC165 {
    
    bool public activated;

    function executeTerms(bytes calldata data) external view override returns (bytes memory newData) {
        return abi.encode(data);
    }

    function tersmExecutedSuccessfully(bytes calldata data) external view override returns (bool) {
        return activated;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(ITermsProcessor).interfaceId || super.supportsInterface(interfaceId);
    }
}