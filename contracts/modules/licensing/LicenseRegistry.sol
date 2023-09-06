// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ZeroAddress, Unauthorized } from "contracts/errors/General.sol";
import { IERC5218 } from "./IERC5218.sol";

/**
 * @title LicenseRegistry
 * @author Raul Martinez
 * @notice Simple NFT tracking the ownership of tradeable Licenses emitted by a RightsManager.
 */
contract LicenseRegistry is ERC721 {

    IERC5218 public immutable RIGHTS_MANAGER;
    
    constructor(address rightsManager, string memory name, string memory symbol) ERC721(name, symbol) {
        if (rightsManager == address(0)) {
            revert ZeroAddress();
        }
        RIGHTS_MANAGER = IERC5218(rightsManager);
    }

    modifier onlyRightsManager() {
        if (msg.sender != address(RIGHTS_MANAGER)) revert Unauthorized();
        _;
    }

    /**
     * @notice Mint a License to the given address. Only caller allowed is the RightsManager.
     * @param to The address to mint the License to.
     * @param tokenId The ID of the License to mint.
     */
    function mint(address to, uint256 tokenId) external onlyRightsManager {
        _mint(to, tokenId);
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        // Minting has already been checked by the RightsManager, but transfers need to pass some checks.
        if (from != address(0)) {
            RIGHTS_MANAGER.transferSublicense(firstTokenId, to);
        }
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }
    

}