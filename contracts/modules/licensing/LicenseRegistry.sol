// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ZeroAddress, Unauthorized } from "contracts/errors/General.sol";
import { IERC5218 } from "contracts/interfaces/modules/licensing/IERC5218.sol";
import { ILicenseRegistry } from "contracts/interfaces/modules/licensing/ILicenseRegistry.sol";
import { Errors } from "contracts/lib/Errors.sol";


/// @title LicenseRegistry
/// @author Raul Martinez
/// @notice Simple NFT tracking the ownership of tradeable Licenses emitted by a RightsManager.
contract LicenseRegistry is ILicenseRegistry, ERC721 {

    IERC5218 private immutable _RIGHTS_MANAGER;
    
    constructor(address rightsManager_, string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        if (rightsManager_ == address(0)) {
            revert Errors.ZeroAddress();
        }
        _RIGHTS_MANAGER = IERC5218(rightsManager_);
    }

    modifier onlyRightsManager() {
        if (msg.sender != address(_RIGHTS_MANAGER)) revert Errors.Unauthorized();
        _;
    }
    
    /// @notice Mint a License to the given address. Only caller allowed is the RightsManager.
    /// @param to_ The address to mint the License to.
    /// @param tokenId_ The ID of the License to mint.
    function mint(address to_, uint256 tokenId_) external onlyRightsManager {
        _mint(to_, tokenId_);
    }

    function exists(uint256 tokenId_) external view returns (bool) {
        return _exists(tokenId_);
    }
    
    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 firstTokenId_,
        uint256 batchSize_
    ) internal virtual override {
        // Minting has already been checked by the RightsManager, but transfers need to pass some checks.
        if (from_ != address(0)) {
            _RIGHTS_MANAGER.transferSublicense(firstTokenId_, to_);
        }
        super._beforeTokenTransfer(from_, to_, firstTokenId_, batchSize_);
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
