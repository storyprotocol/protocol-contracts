// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';

import { IERC721Events } from "contracts/interfaces/IERC721Events.sol";
import { IERC721Errors } from "contracts/interfaces/IERC721Errors.sol";

/// @title Mock ERC-721 Receiver
/// @notice This contract is used to test ERC-721 safe transfers.
contract MockERC721Receiver is IERC721Receiver, IERC721Errors, IERC721Events {

    /// @notice Custom event used to vet whether a receive was successful.
    event ERC721Received(address operator, address from, uint256 tokenId, bytes data);

    // Programmable return value to mock for `onERC721Received` call returns.
    bytes4 private immutable _retval;

    // Whether the contract should throw on `onERC721Received` calls.
    bool private immutable _throws;

    /// @notice Initializes a mock ERC-721 receiver contract.
    /// @param retval The return value to send on `onERC721Received` calls.
    /// @param throws Whether to revert on `onERC721Received` calls.
    constructor(bytes4 retval, bool throws) {
        _retval = retval;
        _throws = throws;
    }

    /// @notice Handles the receiving of an ERC-721 NFT during safe transfers.
    /// @param operator The address approved for operating on the specified NFT.
    /// @param from The address of the current NFT owner.
    /// @param tokenId The id of the NFT being received.
    /// @param data Additional data sent with no specified format.
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
