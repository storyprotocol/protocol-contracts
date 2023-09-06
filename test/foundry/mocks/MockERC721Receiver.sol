// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';

import { IERC721Events } from "contracts/interfaces/IERC721Events.sol";
import { IERC721Errors } from "contracts/interfaces/IERC721Errors.sol";

contract MockERC721Receiver is IERC721Receiver, IERC721Errors, IERC721Events {

    bytes4 private immutable _retval;
    bool private immutable _throws;

    constructor(bytes4 retval, bool throws) {
        _retval = retval;
        _throws = throws;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public override returns (bytes4) {
        if (_throws) {
            revert ERC721SafeTransferUnsupported();
        }
        emit ERC721Received(operator, from, tokenId, data);
        return _retval;
    }
}
