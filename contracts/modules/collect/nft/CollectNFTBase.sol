// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import { InitCollectNFTParams } from "contracts/lib/CollectNFTStructs.sol";
import { ICollectNFT } from "contracts/interfaces/ICollectNFT.sol";
import { ERC721 } from "./ERC721.sol";

/// @title Collect NFT Base Contract
abstract contract CollectNFTBase is ERC721, ICollectNFT {

    address public collectModule;
    address public ipAssetRegistry;
    uint256 public ipAssetId;

    modifier onlyCollectModule() {
        if (msg.sender != collectModule) {
            revert CollectNFTCallerUnauthorized();
        }
        _;
    }

    function initialize(InitCollectNFTParams calldata initParams) public virtual {
        collectModule = initParams.collectModule;
        ipAssetRegistry = initParams.ipAssetRegistry;
        ipAssetId = initParams.ipAssetId;
        if (address(this).code.length > 0) {
            revert CollectNFTAlreadyInitialized();
        }
        _initialize(initParams.data);
    }

    function collect(address collector) onlyCollectModule public virtual {
        _mint(collector, totalSupply);
    }

    function _initialize(bytes calldata data) internal virtual {}

}
