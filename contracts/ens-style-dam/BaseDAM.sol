// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

abstract contract BaseDAM is ERC165 {

    event KeySet(bytes32 indexed key, string value);
    event KeyUnset(bytes32 indexed key, string value);

    mapping(bytes32 => bool) _keys;

    IERC721 public immutable franchiseRegistry;
    IERC721 public immutable storyBlocksRegistry;

    constructor(address _franchiseRegistry, address _storyBlocksRegistry) {
        franchiseRegistry = IERC721(_franchiseRegistry);
        storyBlocksRegistry = IERC721(_storyBlocksRegistry);
    }
    
    function canSetKeys(uint256 franchiseId) internal view virtual returns (bool) {
        return franchiseRegistry.ownerOf(franchiseId) == msg.sender || msg.sender == address(this);
    }

    function canWrite(uint256 storyBlockId) internal view virtual returns (bool) {
        return storyBlocksRegistry.ownerOf(storyBlockId) == msg.sender;
    }

    function setAllowedKey(string memory key, uint256 franchiseId) onlyKeySetter(franchiseId) public {
        _keys[keccak256(abi.encode(key))] = true;
        emit KeySet(keccak256(abi.encode(key)), key);
    }

    function unsetAllowedKey(string calldata key, uint256 franchiseId) onlyKeySetter(franchiseId) external {
        _keys[keccak256(abi.encode(key))] = false;
        emit KeyUnset(keccak256(abi.encode(key)), key);
    }

    function isKeyAllowed(string calldata key) internal view returns (bool) {
         return _keys[keccak256(abi.encode(key))];
    }


    modifier onlyAllowedKey(string calldata key) {
        require(isKeyAllowed(key));
        _;
    }

    modifier onlyKeySetter(uint256 franchiseId) {
        require(canSetKeys(franchiseId));
        _;
    }

    modifier onlyWriter(uint256 storyBlockId) {
        require(canWrite(storyBlockId));
        _;
    }

}