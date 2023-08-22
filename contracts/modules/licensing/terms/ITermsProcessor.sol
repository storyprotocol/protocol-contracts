// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

/**
 * @title ITermsProcessor
 * @author Raul Martinez
 * @notice Interface for licensing terms processors, which encode, decode and execute the terms set on an IERC5218 license parameters,
 * in particular the TermsProcessorConfig struct for the terms parameter in createLicense()
 */
interface ITermsProcessor  {

    /**
     * @notice Encodes the terms to set on a license on creation.
     * This should be called to construct the TermsProcessorConfig struct for the terms parameter in createLicense()
     * @return The encoded terms.
     */
    function encodeTerms() external returns(bytes memory);
    /**
     * @notice Decodes the terms to set on a license on creation.
     * This should be called to before calling executeTerms()
     * // TODO: should this be internal?
     */
    function decodeTerms(bytes calldata data) external;
    /**
     * @notice Executes the terms set on a license on creation.
     * This should be called after decodeTerms()
     * @return Whether the terms were executed successfully.
     */
    function executeTerms() external returns(bool);

}