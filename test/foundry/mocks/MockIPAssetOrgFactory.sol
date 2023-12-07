// SPDX-License-Identifier: UNLICENSED
// See Story Protocol Alpha Agreement: https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.13;

contract MockIPOrgController {
   
    address ipAssetOrgAddress;

    function setIpAssetRegistryAddress(address _ipAssetOrgAddress) external {
        ipAssetOrgAddress = _ipAssetOrgAddress;
    }
   
    function ipAssetOrgForId(
        uint256 franchiseId
    ) public view returns (address) {
        if (franchiseId == 1) {
            return ipAssetOrgAddress;
        }
        return address(0);
    }

}
