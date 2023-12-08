// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { Errors } from "contracts/lib/Errors.sol";
import { SyncBaseHook } from "contracts/hooks/base/SyncBaseHook.sol";
import { TokenGated } from "contracts/lib/hooks/TokenGated.sol";

/// @title Token Gated Hook.
/// @notice Synchronous hook for ensursing a user is the owner of an NFT token.
contract TokenGatedHook is SyncBaseHook {
    using ERC165Checker for address;

    /// @notice Constructs the Token Gated Hook contract.
    /// @param accessControl_ The address of the global access control contract.
    constructor(address accessControl_) SyncBaseHook(accessControl_) {}

    /// @notice Validates the configuration for the token gated hook.
    /// @dev This function checks if the tokenAddress is a valid ERC721 contract.
    /// @param hookConfig_ The configuration data for the hook.
    function _validateConfig(bytes memory hookConfig_) internal view override {
        TokenGated.Config memory config = abi.decode(hookConfig_, (TokenGated.Config));
        address tokenAddress = config.tokenAddress;
        if (tokenAddress == address(0)) {
            revert Errors.ZeroAddress();
        }
        // Check if the configured token address is a valid ERC 721 contract.
        if (!tokenAddress.supportsInterface(type(IERC721).interfaceId)) {
            revert Errors.UnsupportedInterface("IERC721");
        }
    }

    /// @notice Executes a token gated check in a synchronous manner.
    /// @dev This function checks if the "tokenOwner" owns a token of the specified ERC721 token contract.
    /// @param hookConfig_ The configuration of the hook.
    /// @param hookParams_ The parameters for the hook.
    /// @return An empty bytes object, as no data is retured from this hook.
    function _executeSyncCall(
        bytes memory hookConfig_,
        bytes memory hookParams_
    ) internal virtual override returns (bytes memory) {
        TokenGated.Config memory config = abi.decode(hookConfig_, (TokenGated.Config));
        TokenGated.Params memory params = abi.decode(hookParams_, (TokenGated.Params));

        if (params.tokenOwner == address(0)) {
            revert Errors.ZeroAddress();
        }
        // check if tokenOwner own any required token
        if (IERC721(config.tokenAddress).balanceOf(params.tokenOwner) == 0) {
            revert Errors.TokenGatedHook_NotTokenOwner(config.tokenAddress, params.tokenOwner);
        }

        return "";
    }
}
