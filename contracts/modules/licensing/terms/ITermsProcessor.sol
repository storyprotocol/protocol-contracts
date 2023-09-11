// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title ITermsProcessor
 * @author Raul Martinez
 * @notice Interface for licensing terms processors, which encode, decode and execute the terms set on an IERC5218 license parameters,
 * in particular the TermsProcessorConfig struct for the terms parameter in createLicense()
 */
interface ITermsProcessor is IERC165 {

    /**
     * @notice Executes the terms set on a license on creation.
     * This should be called after decodeTerms()
     * @return newData the new data to be set on the license
     */
    function executeTerms(bytes calldata data) external returns(bytes memory newData);

    /// returns true if the terms have been executed successfully or they don't need to be executed, false otherwise
    function termsExecutedSuccessfully(bytes calldata data) external view returns(bool);

}