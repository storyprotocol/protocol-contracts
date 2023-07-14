// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { ILinkingModule } from "../ILinkingModule.sol";

interface ILinkProcessor is IERC165 {

    function processLink(ILinkingModule.LinkParams memory params, bytes calldata data, address linker) external;
}