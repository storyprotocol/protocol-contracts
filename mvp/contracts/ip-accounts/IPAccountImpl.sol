// SPDX-License-Identifier: UNLICENSED
// See Story Protocol Alpha Agreement: https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.13;

import { IERC1271 } from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import { SignatureChecker } from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { IERC1155Receiver } from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC6551Account } from "contracts/interfaces/ip-accounts/IERC6551Account.sol";
import { IIPAccount } from "contracts/interfaces/ip-accounts/IIPAccount.sol";
import { Errors } from "contracts/lib/Errors.sol";

/// @title IPAccountImpl
contract IPAccountImpl is IERC165, IIPAccount, IERC1271 {
    using SafeERC20 for IERC20;

    uint256 public state;
    // ERC20 token => amount
    mapping(address => uint256) public entitled;
    // ERC20 token => amount
    mapping(address => uint256) public withdrawn;

    receive() external payable {}

    /// @dev {See IIPAccount-safeTransferFrom}
    function safeTransferFrom(
        address nftContract_,
        address from_,
        address to_,
        uint256 tokenId_
    ) external {
        if (!_isValidSigner(msg.sender)) revert Errors.IPAccountImpl_CallerNotOwner();
        ++state;
        IERC721(nftContract_).safeTransferFrom(from_, to_, tokenId_);
    }

    // TODO: authorization check that only the royaltyDistributor can call this function
    function sendRoyaltyForDistribution(
        address distributor_,
        address erc20_
    ) external {
        IERC20(erc20_).safeTransfer(
            distributor_,
            IERC20(erc20_).balanceOf(address(this)) +
            withdrawn[erc20_] -
            entitled[erc20_]
        );
    }

    function isValidSignature(
        bytes32 hash_,
        bytes memory signature_
    ) external view returns (bytes4 magicValue) {
        bool isValid = SignatureChecker.isValidSignatureNow(
            owner(),
            hash_,
            signature_
        );
        if (isValid) {
            return IERC1271.isValidSignature.selector;
        }

        return "";
    }

    /// @dev {See IERC6551Account-isValidSigner}
    function isValidSigner(
        address signer_,
        bytes calldata
    ) external view returns (bytes4) {
        if (_isValidSigner(signer_)) {
            return IERC6551Account.isValidSigner.selector;
        }

        return bytes4(0);
    }

    function supportsInterface(
        bytes4 interfaceId_
    ) external pure returns (bool) {
        return (interfaceId_ == type(IERC6551Account).interfaceId ||
            interfaceId_ == type(IERC1155Receiver).interfaceId ||
            interfaceId_ == type(IERC721Receiver).interfaceId ||
            interfaceId_ == type(IERC165).interfaceId);
    }

    /// @dev {See IERC6551Account-token}
    function token() public view override returns (uint256, address, uint256) {
        bytes memory footer = new bytes(0x60);
        // 0x4d = 77 bytes (ERC-1167 Header, address, ERC-1167 Footer, salt)
        // 0x60 = 96 bytes (chainId, tokenContract, tokenId)
        //    ERC-1167 Header               (10 bytes)
        //    <implementation (address)>    (20 bytes)
        //    ERC-1167 Footer               (15 bytes)
        //    <salt (uint256)>              (32 bytes)
        //    <chainId (uint256)>           (32 bytes)
        //    <tokenContract (address)>     (32 bytes)
        //    <tokenId (uint256)>           (32 bytes)
        assembly {
            extcodecopy(address(), add(footer, 0x20), 0x4d, 0x60)
        }

        return abi.decode(footer, (uint256, address, uint256));
    }

    function owner() public view returns (address) {
        (uint256 chainId, address contractAddress, uint256 tokenId) = token();
        if (chainId != block.chainid) return address(0);
        return IERC721(contractAddress).ownerOf(tokenId);
    }

    function _isValidSigner(address signer_) internal view returns (bool) {
        return signer_ == owner();
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}
