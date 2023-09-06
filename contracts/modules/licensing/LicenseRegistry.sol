// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ZeroAddress, Unauthorized } from "contracts/errors/General.sol";
import { IERC5218 } from "./IERC5218.sol";
import { ILicenseRegistry } from "./ILicenseRegistry.sol";

/**
 * @title LicenseRegistry
 * @author Raul Martinez
 * @notice Simple NFT tracking the ownership of tradeable Licenses emitted by a RightsManager.
 */
contract LicenseRegistry is ILicenseRegistry, ERC721 {

    IERC5218 private immutable _RIGHTS_MANAGER;
    
    constructor(address _rightsManager, string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        if (_rightsManager == address(0)) {
            revert ZeroAddress();
        }
        _RIGHTS_MANAGER = IERC5218(_rightsManager);
    }

    modifier onlyRightsManager() {
        if (msg.sender != address(_RIGHTS_MANAGER)) revert Unauthorized();
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
            _RIGHTS_MANAGER.transferSublicense(firstTokenId, to);
        }
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function getRightsManager() external view override returns (address) {
        return address(_RIGHTS_MANAGER);
    }

    function name() public view override(ERC721, ILicenseRegistry) returns (string memory) {
        return super.name();
    }
    
    function symbol() public view override(ERC721, ILicenseRegistry) returns (string memory) {
        return super.symbol();
    }

}