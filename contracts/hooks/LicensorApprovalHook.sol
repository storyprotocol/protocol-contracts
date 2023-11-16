// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { HookResult } from "contracts/interfaces/hooks/base/IHook.sol";
import { AsyncBaseHook } from "contracts/hooks/base/AsyncBaseHook.sol";
import { Errors } from "contracts/lib/Errors.sol";

contract LicensorApprovalHook is AsyncBaseHook {
    constructor(address accessControl_) AsyncBaseHook(accessControl_) {}

    event LicensorApprovalRequested(
        address indexed licensor,
        uint256 indexed licenseId,
        bytes32 requestId
    );
    event LicenseApproved(
        address indexed licensor,
        uint256 indexed licenseId
    );

    enum ApprovalStatus {
        Unset,
        Requested,
        Approved,
        Denied
    }
    struct LicensorApproval {
        address licensor;
        ApprovalStatus status;
    }

    mapping(bytes32 => LicensorApproval) public licensorApprovals;

    function _validateConfig(
        bytes memory hookConfig_
    ) internal view virtual override {
        // No op
    }

    function _requestAsyncCall(
        bytes memory hookConfig_,
        bytes memory hookParams_
    )
        internal
        virtual
        override
        returns (bytes memory hookData, bytes32 requestId)
    {
        (address licensor, uint256 licenseId) = abi.decode(
            hookParams_,
            (address, uint256)
        );
        requestId = keccak256(hookParams_);
        if (licensor == address(0)) {
            revert Errors.LicensorApprovalHook_InvalidLicensor();
        }
        if (licenseId == 0) {
            revert Errors.LicensorApprovalHook_InvalidLicenseId();
        }
        LicensorApproval storage approval = licensorApprovals[requestId];
        if (approval.status != ApprovalStatus.Unset) {
            revert Errors.LicensorApprovalHook_ApprovalAlreadyRequested();
        }
        approval.status = ApprovalStatus.Requested;
        emit LicensorApprovalRequested(licensor, licenseId, requestId);
        return (
            abi.encode(hookConfig_, hookParams_),
            requestId
        );
    }

    function respondApprovalRequest(
        address licensor_,
        uint256 licenseId_,
        ApprovalStatus status_
    ) external {
        bytes32 requestId = keccak256(abi.encode(licensor_, licenseId_));
        if (licensorApprovals[requestId].status != ApprovalStatus.Requested) {
            revert Errors.LicensorApprovalHook_NoApprovalRequested();
        }
        if (status_ != ApprovalStatus.Approved && status_ != ApprovalStatus.Denied) {
            revert Errors.LicensorApprovalHook_InvalidResponseStatus();
        }
        licensorApprovals[requestId] = LicensorApproval(licensor_, status_);
        emit LicenseApproved(licensor_, licenseId_);
        _handleCallback(requestId, abi.encode(licenseId_, status_));
    }

    
    function _callbackCaller(
        bytes32 requestId_
    ) internal view virtual override returns (address) {
        return licensorApprovals[requestId_].licensor;
    }
}