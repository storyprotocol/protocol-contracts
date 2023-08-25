// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

interface ICollectModuleEventsAndErrors {

    /// @notice Collect action is not authorized.
    error CollectModuleCollectUnauthorized();

    /// @notice CollectModule Caller is unauthorized.
    error CollectModuleCallerUnauthorized();

}
