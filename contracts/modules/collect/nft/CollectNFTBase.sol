// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import { ICollectModule } from "contracts/interfaces/ICollectModule.sol";
import { ICollectNFT } from "contracts/interfaces/ICollectNFT.sol";
import { IIPAssetRegistry } from "contracts/ip-assets/IIPAssetRegistry.sol";

import { InitCollectNFTParams } from "contracts/lib/CollectNFTStructs.sol";
import { ERC721 } from "./ERC721.sol";

/// @title Collect NFT Base Contract
/// @notice This is the Story Protocol base collect NFT that SHOULD be extended
///         when creating custom collect NFTs for an IP asset collect module.
///         A collect NFT represents either an open or limited edition NFT that
///         mirrors, in some way or another, the IP asset to that is bound to.
abstract contract CollectNFTBase is ERC721, ICollectNFT {

    // The collect module managing collection for the collect NFT.
    ICollectModule public collectModule;

    // The franchise registry that the IP asset is registered under.
    IIPAssetRegistry public ipAssetRegistry;

    // The id of the IP asset that the collect NFT is bound to.
    uint256 public ipAssetId;

    // Internal bool tracking whether the collect NFT has been initialized.
    bool private _initialized;

    /// @notice Ensures calls may only be invoked by the parent collect module.
    modifier onlyCollectModule() {
        if (msg.sender != address(collectModule)) {
            revert CollectNFTCallerUnauthorized();
        }
        _;
    }

    /// @notice Instantiates the collect NFT implementation.
    /// @dev Actual creation for IP assets will be performed by `initialize()`,
    ///      this is only included to prevent initialization of the NFT impl.
    constructor() {
        _initialized = true;
    }

    /// @notice Returns the total # of collect NFTs that exist for an IP asset.
    /// @return The total number of collect NFTs in the collection.
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /// @notice Initializes a collect NFT for subsequent collection.
    /// @param initParams Collect NFT init data, including bound franchise IP 
    ///        asset registry, IP asset id, and generic unformatted init data.
    function initialize(InitCollectNFTParams calldata initParams) public virtual {

        // Revert if this collect NFT has already been initialized.
        if (_initialized) {
            revert CollectNFTAlreadyInitialized();
        }

        _initialized = true;
        collectModule = ICollectModule(msg.sender);
        ipAssetRegistry = IIPAssetRegistry(initParams.ipAssetRegistry);
        ipAssetId = initParams.ipAssetId;

        // Ensure the bound IP asset in fact exists.
        try ipAssetRegistry.ownerOf(ipAssetId) {
        } catch {
            revert CollectNFTIPAssetNonExistent();
        }

        // Perform any additional collect NFT initialization.
        _initialize(initParams.data);
    }

    /// @notice Performs a collect, minting the NFT to address `collector`.
    /// @param collector The address of the target designated for collection.
    /// @param data Additional unformatted bytes data for optional processing.
    /// @return tokenId The id of the minted collect NFT.
    function collect(address collector, bytes calldata data) onlyCollectModule public virtual returns (uint256 tokenId) {
        tokenId = _totalSupply;
        _mint(collector, tokenId);
        _collect(data);
    }

    /// @dev Performs any additional initialization of the collect NFT.
    /// @param data Additional unformatted data to be used for initialization.
    function _initialize(bytes calldata data) internal virtual {}

    /// @dev Performs any additional collect processing for the collect NFT.
    /// @param data Additional unformatted data to be used for collection.
    function _collect(bytes calldata data) internal virtual {}
}