// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IStoryBlockAware } from "../IStoryBlockAware.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract IPStorage is IStoryBlockAware {

    using EnumerableSet for EnumerableSet.Bytes32Set;

    struct StoryBlockData {
        string name;
        string description;
        string mediaUrl;
        StoryBlock blockType;
    }

    struct StoryBlockFields {
        mapping(bytes32 => string) _stringData;
        mapping(bytes32 => uint256) _uintData;
        mapping(bytes32 => address) _addressData;
        mapping(bytes32 => bytes) _bytesData;
    }

    struct StoryBlockKeys {
        EnumerableSet.Bytes32Set _stringKeys;
        EnumerableSet.Bytes32Set _uintKeys;
        EnumerableSet.Bytes32Set _addressKeys;
        EnumerableSet.Bytes32Set _bytesKeys;
    }

    mapping(uint256 => mapping(uint256 => StoryBlockData)) private _storyBlocks;
    mapping(uint256 => mapping(uint256 => StoryBlockFields)) private _storyBlockFields;
    
    mapping(uint256 => StoryBlockKeys) private _storyBlockKeys;

    IERC721 public immutable franchiseRegistry;
    IERC721 public immutable storyBlocksRegistry;

    modifier onlyWriter(uint256 storyBlockId) {
        require(canWrite(storyBlockId), "Unauthorized Writer");
        _;
    }

    modifier onlyKeySetter(uint256 franchiseId) {
        require(canSetKeys(franchiseId), "Unauthorized Key Setter");
        _;
    }

    constructor(address _franchiseRegistry, address _storyBlocksRegistry) {
        franchiseRegistry = IERC721(_franchiseRegistry);
        storyBlocksRegistry = IERC721(_storyBlocksRegistry);
    }

    function canWrite(uint256 storyBlockId) internal view virtual returns (bool) {
        return storyBlocksRegistry.ownerOf(storyBlockId) == msg.sender;
    }

    function canSetKeys(uint256 franchiseId) internal view virtual returns (bool) {
        return franchiseRegistry.ownerOf(franchiseId) == msg.sender || msg.sender == address(this);
    }

    function writeStoryBlock(
        uint256 franchiseId,
        uint256 storyBlockId,
        StoryBlock blockType,
        string calldata name,
        string calldata description,
        string calldata mediaUrl
    ) external onlyWriter(storyBlockId) {
        StoryBlockData storage sbd = _storyBlocks[franchiseId][storyBlockId];
        sbd.name = name;
        sbd.description = description;
        sbd.blockType = blockType;
        sbd.mediaUrl = mediaUrl;
    }

    function readStoryBlock(uint256 franchiseId, uint256 storyBlockId) external view returns (StoryBlockData memory) {
        return _storyBlocks[franchiseId][storyBlockId];
    }

    /// String keys

    function setAllowedStringKey(uint256 franchiseId, bytes32 key) onlyKeySetter(franchiseId) public {
        _storyBlockKeys[franchiseId]._stringKeys.add(key);
    }

    function getAllowedStringKeys(uint256 franchiseId) public view returns (bytes32[] memory) {
        return _storyBlockKeys[franchiseId]._stringKeys.values();
    }

    function writeStringKeys(uint256 franchiseId, uint256 storyBlockId, bytes32[] calldata keys, string[] calldata values) external onlyWriter(storyBlockId) {
        require(keys.length == values.length, "Keys and Values must be same length");
        StoryBlockFields storage sbf = _storyBlockFields[franchiseId][storyBlockId];
        for (uint256 i = 0; i < keys.length; i++) {
            sbf._stringData[keys[i]] = values[i];
        }
    }

    /// Uint keys

    function setAllowedUintKey(uint256 franchiseId, bytes32 key) onlyKeySetter(franchiseId) public {
        _storyBlockKeys[franchiseId]._uintKeys.add(key);
    }

    function getAllowedUintKeys(uint256 franchiseId) public view returns (bytes32[] memory) {
        return _storyBlockKeys[franchiseId]._uintKeys.values();
    }

    function writeBlockUintFields(uint256 franchiseId, uint256 storyBlockId, bytes32[] calldata keys, uint256[] calldata values) external onlyWriter(storyBlockId) {
        StoryBlockFields storage sbf = _storyBlockFields[franchiseId][storyBlockId];
        for (uint256 i = 0; i < keys.length; i++) {
            sbf._uintData[keys[i]] = values[i];
        }
    }

    /// Address keys
    function setAllowedAddressKey(uint256 franchiseId, bytes32 key) onlyKeySetter(franchiseId) public {
        _storyBlockKeys[franchiseId]._addressKeys.add(key);
    }

    function getAllowedAddressKeys(uint256 franchiseId) public view returns (bytes32[] memory) {
        return _storyBlockKeys[franchiseId]._addressKeys.values();
    }

    function writeBlockAddressFields(uint256 franchiseId, uint256 storyBlockId, bytes32[] calldata keys, address[] calldata values) external onlyWriter(storyBlockId) {
        require(keys.length == values.length, "Keys and Values must be same length");
        StoryBlockFields storage sbf = _storyBlockFields[franchiseId][storyBlockId];
        for (uint256 i = 0; i < keys.length; i++) {
            sbf._addressData[keys[i]] = values[i];
        }
    }

    /// Bytes keys
    function getAllowedBytesKeys(uint256 franchiseId) public view returns (bytes32[] memory) {
        return _storyBlockKeys[franchiseId]._bytesKeys.values();
    }

    function setAllowedBytesKey(uint256 franchiseId, bytes32 key) onlyKeySetter(franchiseId) public {
        _storyBlockKeys[franchiseId]._bytesKeys.add(key);
    }

    function writeBlockBytesFields(uint256 franchiseId, uint256 storyBlockId, bytes32[] calldata keys, bytes[] calldata values) external onlyWriter(storyBlockId) {
        require(keys.length == values.length, "Keys and Values must be same length");
        StoryBlockFields storage sbf = _storyBlockFields[franchiseId][storyBlockId];
        for (uint256 i = 0; i < keys.length; i++) {
            sbf._bytesData[keys[i]] = values[i];
        }
    }

}