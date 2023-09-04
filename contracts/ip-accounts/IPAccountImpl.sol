// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "./IERC6551Account.sol";
import "./IIPAccount.sol";

/**
 * @title IPAccountImpl
 */
contract IPAccountImpl is
    IERC165,
    IIPAccount,
    IERC1271
{
    uint256 public state;

    receive() external payable {}

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return (interfaceId == type(IERC6551Account).interfaceId ||
            interfaceId == type(IERC1155Receiver).interfaceId ||
            interfaceId == type(IERC721Receiver).interfaceId ||
            interfaceId == type(IERC165).interfaceId);
    }

    /**
     * @dev {See IERC6551Account-token}
     */
    function token()
        public
        view
        override
        returns (
            uint256,
            address,
            uint256
        )
    {
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

    function isValidSignature(bytes32 hash, bytes memory signature)
        external
        view
        returns (bytes4 magicValue)
    {
        bool isValid = SignatureChecker.isValidSignatureNow(owner(), hash, signature);
        if (isValid) {
            return IERC1271.isValidSignature.selector;
        }

        return "";
    }

    /**
     * @dev {See IERC6551Account-isValidSigner}
     */
    function isValidSigner(address signer, bytes calldata) external view returns (bytes4) {
        if (_isValidSigner(signer)) {
            return IERC6551Account.isValidSigner.selector;
        }

        return bytes4(0);
    }

    function owner() public view returns (address) {
        (uint256 chainId, address contractAddress, uint256 tokenId) = token();
        if (chainId != block.chainid) return address(0);
        return IERC721(contractAddress).ownerOf(tokenId);
    }

    function _isValidSigner(address signer) internal view returns (bool) {
        return signer == owner();
    }

    /**
     * @dev {See IIPAccount-safeTransferFrom}
     */
    function safeTransferFrom(address nftContract, address from, address to, uint256 tokenId) external {
        require(_isValidSigner(msg.sender), "Caller is not owner");
        ++state;
        IERC721(nftContract).safeTransferFrom(from, to, tokenId);
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
