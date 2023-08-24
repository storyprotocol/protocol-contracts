// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { DataTypes } from './libraries/DataTypes.sol';

interface IStoryProtocol {
    function registerFranchise(DataTypes.FranchiseCreationParams calldata params) external returns (uint256, address);
//    function ipAssetRegistryForFranchise(uint256 franchiseId) public view returns (address);
//    function isIpAssetRegistry(address ipAssetRegistry) external view returns(bool);
//
//    function createIPAsset(
//        IPAsset sb,
//        string calldata name,
//        string calldata _description,
//        string calldata mediaUrl
//    ) external returns (uint256);
//    function readIPAsset(uint256 IPAssetId) external view returns (IPAssetData memory);
//
//    function relate(RelationshipParams calldata params, bytes calldata data) external;
//    function unrelate(RelationshipParams calldata params) external;
//    function areTheyRelated(RelationshipParams calldata params) external view returns (bool);
//    function isRelationshipExpired(RelationshipParams calldata params) external view returns (bool);
//    function setRelationshipConfig(string calldata name, SetRelationshipConfigParams calldata params) external returns(bytes32 relationshipId);
//    function getRelationshipId(string calldata name) external view returns (bytes32);
//    function unsetRelationshipConfig(bytes32 relationshipId) external;
//    function getRelationshipConfig(bytes32 relationshipId) external view returns (RelationshipConfig memory);
//    function getRelationshipConfigDecoded(bytes32 relationshipId) external view returns (SetRelationshipConfigParams memory);

    //Todo: add functions from other new modules
    //Todo: add functions for workflows
}
