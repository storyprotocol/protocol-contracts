// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

contract MockIPOrgFactory {
   
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
