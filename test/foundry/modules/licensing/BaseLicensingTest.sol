// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { Licensing } from "contracts/lib/modules/Licensing.sol";
import { ShortStrings, ShortString } from "@openzeppelin/contracts/utils/ShortStrings.sol";
import 'test/foundry/utils/BaseTest.sol';
import { IHook } from "contracts/interfaces/hooks/base/IHook.sol";
import { OffChain } from "contracts/lib/OffChain.sol";

contract BaseLicensingTest is BaseTest {
    using ShortStrings for *;

    ShortString public textTermId = "text_term_id".toShortString();
    ShortString public nonCommTextTermId = "non_comm_text_term_id".toShortString();
    ShortString public commTextTermId = "comm_text_term_id".toShortString();

    function setUp() virtual override public {
        super.setUp();
        licensingModule.addTermCategory("test_category");
        licensingModule.addTerm(
            "test_category",
            "text_term_id",
            Licensing.LicensingTerm({
                comStatus: Licensing.CommercialStatus.Both,
                text: OffChain.Content({
                    url: "https://example.com"
                }),
                hook: IHook(address(0))
            }
        ));
        licensingModule.addTerm(
            "test_category",
            "non_comm_text_term_id",
            Licensing.LicensingTerm({
                comStatus: Licensing.CommercialStatus.NonCommercial,
                text: OffChain.Content({
                    url: "https://example.com"
                }),
                hook: IHook(address(0))
            }
        ));
        licensingModule.addTerm(
            "test_category",
            "comm_text_term_id",
            Licensing.LicensingTerm({
                comStatus: Licensing.CommercialStatus.Commercial,
                text: OffChain.Content({
                    url: "https://example.com"
                }),
                hook: IHook(address(0))
            }
        ));
    }

    function getEmptyLicensingFramework() public pure returns (Licensing.FrameworkConfig memory) {
        return
            Licensing.FrameworkConfig({
                comTermsConfig: Licensing.TermsConfig({
                    termIds: new ShortString[](0),
                    termData: new bytes[](0)
                }),
                nonComTermsConfig: Licensing.TermsConfig({
                    termIds: new ShortString[](0),
                    termData: new bytes[](0)
                })
            });
    }

    function getNonCommLicensingFramework(
        ShortString termId,
        bytes memory data
    ) public pure returns (Licensing.FrameworkConfig memory) {
        ShortString[] memory termIds = new ShortString[](1);
        termIds[0] = termId;
        bytes[] memory termData = new bytes[](1);
        termData[0] = data;
        return
            Licensing.FrameworkConfig({
                comTermsConfig: Licensing.TermsConfig({
                    termIds: new ShortString[](0),
                    termData: new bytes[](0)
                }),
                nonComTermsConfig: Licensing.TermsConfig({
                    termIds: termIds,
                    termData: termData
                })
            });
    }

    function getCommLicensingFramework(
        ShortString termId,
        bytes memory data
    ) public pure returns (Licensing.FrameworkConfig memory) {
        ShortString[] memory termIds = new ShortString[](1);
        termIds[0] = termId;
        bytes[] memory termData = new bytes[](1);
        termData[0] = data;
        return
            Licensing.FrameworkConfig({
                comTermsConfig: Licensing.TermsConfig({
                    termIds: termIds,
                    termData: termData
                }),
                nonComTermsConfig: Licensing.TermsConfig({
                    termIds: termIds,
                    termData: termData
                })
            });
    }
}
