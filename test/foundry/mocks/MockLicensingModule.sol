pragma solidity ^0.8.19;

import { ILicensingModule } from "contracts/interfaces/modules/licensing/ILicensingModule.sol";
import { ITermsProcessor } from "contracts/interfaces/modules/licensing/terms/ITermsProcessor.sol";
import { MockTermsProcessor } from "./MockTermsProcessor.sol";
import { Licensing } from "contracts/lib/modules/Licensing.sol";

library LibMockIPAssetGroupConfig {
    function getMockIPAssetGroupConfig()
        internal
        pure
        returns (Licensing.IPAssetGroupConfig memory)
    {
        return
            Licensing.IPAssetGroupConfig({
                nonCommercialConfig: Licensing.IpAssetConfig({
                    canSublicense: false,
                    franchiseRootLicenseId: 0
                }),
                nonCommercialTerms: Licensing.TermsProcessorConfig({
                    processor: ITermsProcessor(address(0)),
                    data: ""
                }),
                commercialConfig: Licensing.IpAssetConfig({
                    canSublicense: false,
                    franchiseRootLicenseId: 0
                }),
                commercialTerms: Licensing.TermsProcessorConfig({
                    processor: ITermsProcessor(address(0)),
                    data: ""
                }),
                rootIpAssetHasCommercialRights: false,
                revoker: address(0x5656565),
                commercialLicenseUri: ""
            });
    }

    function getTermsProcessorConfig() public returns(Licensing.TermsProcessorConfig memory terms, MockTermsProcessor termsProcessor){
        termsProcessor = new MockTermsProcessor();
        terms = Licensing.TermsProcessorConfig({
            processor: termsProcessor,
            data: abi.encode("terms")
        });
    }
}

contract MockLicensingModule is ILicensingModule {
    function configureIPAssetGroupLicensing(
        uint256 franchiseId,
        Licensing.IPAssetGroupConfig memory config
    ) external override {
        // No-op
    }

    function getIPAssetGroupConfig(
        uint256
    ) external pure override returns (Licensing.IPAssetGroupConfig memory) {
        return LibMockIPAssetGroupConfig.getMockIPAssetGroupConfig();
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
