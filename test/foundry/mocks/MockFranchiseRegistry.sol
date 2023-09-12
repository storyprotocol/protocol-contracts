// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

contract MockFranchiseRegistry {
   
    address ipAssetRegistryAddress;

    function setIpAssetRegistryAddress(address _ipAssetRegistryAddress) external {
        ipAssetRegistryAddress = _ipAssetRegistryAddress;
    }
   
    function ipAssetRegistryForId(
        uint256 franchiseId
    ) public view returns (address) {
        if (franchiseId == 1) {
            return ipAssetRegistryAddress;
        }
        return address(0);
    }

}
