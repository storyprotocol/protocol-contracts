import {ILicensingModule} from "contracts/modules/licensing/ILicensingModule.sol";
import {IERC5218} from "contracts/modules/licensing/IERC5218.sol";
import {ITermsProcessor} from "contracts/modules/licensing/terms/ITermsProcessor.sol";

library LibMockFranchiseConfig {
    function getMockFranchiseConfig()
        internal
        pure
        returns (ILicensingModule.FranchiseConfig memory)
    {
        return
            ILicensingModule.FranchiseConfig({
                nonCommercialConfig: ILicensingModule.IpAssetConfig({
                    canSublicense: false,
                    franchiseRootLicenseId: 0
                }),
                nonCommercialTerms: IERC5218.TermsProcessorConfig({
                    processor: ITermsProcessor(address(0)),
                    data: ""
                }),
                commercialConfig: ILicensingModule.IpAssetConfig({
                    canSublicense: false,
                    franchiseRootLicenseId: 0
                }),
                commercialTerms: IERC5218.TermsProcessorConfig({
                    processor: ITermsProcessor(address(0)),
                    data: ""
                }),
                rootIpAssetHasCommercialRights: false,
                revoker: address(0x5656565),
                commercialLicenseUri: ""
            });
    }
}

contract MockLicensingModule is ILicensingModule {
    function configureFranchiseLicensing(
        uint256 franchiseId,
        FranchiseConfig memory config
    ) external override {
        // No-op
    }

    function getFranchiseConfig(
        uint256
    ) external pure override returns (FranchiseConfig memory) {
        return LibMockFranchiseConfig.getMockFranchiseConfig();
    }

    function getNonCommercialLicenseURI()
        external
        pure
        override
        returns (string memory)
    {
        return "mockmock";
    }
}
