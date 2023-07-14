// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { ILinkProcessor } from "./LinkProcessors/ILinkProcessor.sol";
import { IPAsset } from "contracts/IPAsset.sol";

interface ILinkingModule {

    event Linked(
        address sourceContract,
        uint256 sourceId,
        address destContract,
        uint256 destId,
        bytes32 linkId
    );
    event Unlinked(
        address sourceContract,
        uint256 sourceId,
        address destContract,
        uint256 destId,
        bytes32 linkId
    );

    event ProtocolLinkSet(
        bytes32 linkId,
        uint256 sourceIPAssetTypeMask,
        uint256 destIPAssetTypeMask,
        bool linkOnlySameFranchise,
        address linkProcessor
    );
    event ProtocolLinkUnset(bytes32 linkId);

    error NonExistingLink();
    error IntentAlreadyRegistered();
    error UnsupportedLinkSource();
    error UnsupportedLinkDestination();
    error CannotLinkToAnotherFranchise();

    struct LinkConfig {
        uint256 sourceIPAssetTypeMask;
        uint256 destIPAssetTypeMask;
        bool linkOnlySameFranchise;
        ILinkProcessor processor;
    }

    struct SetLinkParams {
        IPAsset[] sourceIPAssets;
        bool allowedExternalSource;
        IPAsset[] destIPAssets;
        bool allowedExternalDest;
        bool linkOnlySameFranchise;
        address linkProcessor;
    }

    struct LinkParams {
        address sourceContract;
        uint256 sourceId;
        address destContract;
        uint256 destId;
        bytes32 linkId;
    }

    function link(LinkParams calldata params, bytes calldata data) external;
    function unlink(LinkParams calldata params) external;
    function areTheyLinked(LinkParams calldata params) external view returns (bool);
    function setProtocolLink(bytes32 linkId, SetLinkParams calldata params) external;
    function unsetProtocolLink(bytes32 linkId) external;
    function protocolLinks(bytes32 linkId) external view returns (LinkConfig memory);
}