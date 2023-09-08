// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import { InitCollectNFTParams } from "contracts/lib/CollectNFTStructs.sol";
import { ICollectNFT } from "contracts/interfaces/ICollectNFT.sol";
import { ERC721 } from "./ERC721.sol";
import { ICollectModule } from "contracts/interfaces/ICollectModule.sol";
import { IIPAssetRegistry } from "contracts/ip-assets/IIPAssetRegistry.sol";

/// @title Collect NFT Base Contract
abstract contract CollectNFTBase is ERC721, ICollectNFT {

    ICollectModule public collectModule;
    IIPAssetRegistry public ipAssetRegistry;
    uint256 public ipAssetId;
    bool private _initialized;

    modifier onlyCollectModule() {
        if (msg.sender != address(collectModule)) {
            revert CollectNFTCallerUnauthorized();
        }
        _;
    }

    constructor() {
        _initialized = true;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function initialize(InitCollectNFTParams calldata initParams) public virtual {
        if (_initialized) {
            revert CollectNFTAlreadyInitialized();
        }
        _initialized = true;
        collectModule = ICollectModule(msg.sender);
        ipAssetRegistry = IIPAssetRegistry(initParams.ipAssetRegistry);
        ipAssetId = initParams.ipAssetId;
        try ipAssetRegistry.ownerOf(ipAssetId) {
        } catch {
            revert CollectNFTIPAssetNonExistent();
        }
        _initialize(initParams.data);
    }

    function collect(address collector, bytes calldata data) onlyCollectModule public virtual returns (uint256) {
        uint256 tokenId = _totalSupply;
        _mint(collector, tokenId);
        _collect(data);
        return tokenId;
    }

    function _initialize(bytes calldata data) internal virtual {}

    function _collect(bytes calldata data) internal virtual {}
}
