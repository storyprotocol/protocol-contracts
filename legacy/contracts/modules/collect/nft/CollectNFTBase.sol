// SPDX-License-Identifier: UNLICENSED
// See Story Protocol Alpha Agreement: https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.18;

import { ICollectModule } from "contracts/interfaces/modules/collect/ICollectModule.sol";
import { ICollectNFT } from "contracts/interfaces/modules/collect/ICollectNFT.sol";
import { IIPOrg } from "contracts/interfaces/ip-org/IIPOrg.sol";

import { IPAssetRegistry } from "contracts/IPAssetRegistry.sol";
import { Collect } from "contracts/lib/modules/Collect.sol";
import { Errors } from "contracts/lib/Errors.sol";
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
    IIPOrg public ipAssetOrg;
    
    // The registry of the IP Assets.
    IPAssetRegistry public registry;

    // The id of the IP asset that the collect NFT is bound to.
    uint256 public ipAssetId;

    // Internal bool tracking whether the collect NFT has been initialized.
    bool private _initialized;

    /// @notice Ensures calls may only be invoked by the parent collect module.
    modifier onlyCollectModule() {
        if (msg.sender != address(collectModule)) {
            revert Errors.CollectNFT_CallerUnauthorized();
        }
        _;
    }

    /// @notice Instantiates the collect NFT implementation.
    /// @dev Actual creation for IP assets will be performed by `initialize()`,
    ///      this is only included to prevent initialization of the NFT impl.
    constructor() {
        _initialized = true;
    }

    /// @notice Initializes a collect NFT for subsequent collection.
    /// @param initParams_ Collect NFT init data, including bound franchise IP 
    ///        asset registry, IP asset id, and generic unformatted init data.
    function initialize(Collect.InitCollectNFTParams calldata initParams_) public virtual {

        // Revert if this collect NFT has already been initialized.
        if (_initialized) {
            revert Errors.CollectNFT_AlreadyInitialized();
        }

        _initialized = true;
        collectModule = ICollectModule(msg.sender);
        ipAssetOrg = IIPOrg(initParams_.ipAssetOrg);
        ipAssetId = initParams_.ipAssetId;
        registry = IPAssetRegistry(initParams_.registry);

        // Ensure the bound IP asset in fact exists.
        if (registry.ipAssetOwner(ipAssetId) == address(0)) {
            revert Errors.CollectNFT_IPAssetNonExistent();
        }

        // Perform any additional collect NFT initialization.
        _initialize(initParams_.data);
    }

    /// @notice Performs a collect, minting the NFT to address `collector`.
    /// @param collector_ The address of the target designated for collection.
    /// @param data_ Additional unformatted bytes data for optional processing.
    /// @return tokenId The id of the minted collect NFT.
    function collect(address collector_, bytes calldata data_) onlyCollectModule public virtual returns (uint256 tokenId) {
        tokenId = _totalSupply;
        _mint(collector_, tokenId);
        _collect(data_);
    }

    /// @notice Returns the total # of collect NFTs that exist for an IP asset.
    /// @return The total number of collect NFTs in the collection.
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /// @dev Performs any additional initialization of the collect NFT.
    /// @param data_ Additional unformatted data to be used for initialization.
    function _initialize(bytes calldata data_) internal virtual {}

    /// @dev Performs any additional collect processing for the collect NFT.
    /// @param data_ Additional unformatted data to be used for collection.
    function _collect(bytes calldata data_) internal virtual {}
}
