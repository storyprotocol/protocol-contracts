# @story-protocol/contracts

## 0.2.0

### Alpha Version

    Unification of the modules and registries of the MVP under a common architecture:

    **Protocol registries and repositories:**

    -   IPAssetRegistry: Source of truth for the registered IPAssets across the protocol.
    -   ModuleRegistry: Registers the protocol modules, and acts router of module execution and configuration.
    -   LicenseRegistry: Registers the License NFTs.
    -   LicensingFrameworkRepo: Holds the supported licensing framework, with parameters expressing the licensing terms and their configurations. Currently, it will only hold the SPUML-1.0 framework.

    **IP Org related contracts:**

    -   IPOrgController: factory for IPOrg creation, registering organizations that can configure the modules to form a common environment under which IPAs can be registered.
    -   IPOrg: acts as an NFT view into the global IPAssetRegistry. Adds metadata personalization, and its owner can configure the modules.

    **Modules**

    -   BaseModule: defines a common architecture and entrypoints for all modules, along with references to the registries.
    -   HookRegistry: every module can register hooks, configurable actions to be executed before and after the module action.
    -   Registration: logic to create IPAs under an IPOrg.
    -   RelationshipModule: allow the creation of relationship types (protocol wide and specific to ipOrgs) that can relate different elements of the protocol (for example, to express a remixing content graph within an IPOrg)
    -   Licensing: allows IpOrg to register a common legal framework with some default terms, and has the logic for users to create licenses and link them to IPAs

    **Hooks**

    -   SyncBaseHook: to be inherited by all the synchronous actions (payment, token gating, etc)
    -   AsyncBaseHook: to be inherited by all the asynchronous actions (oracles, multi step/sig actions, etc)
    -   TokenGatedHook: checks if caller owns an NFT, if not the module action cannot continue.
    -   PolygonTokenHook: example async hook, checks if caller owns tokens in the Polygon network.

    **"Frontend" Contracts**

    -   StoryProtocol: exposes the write functionality for all the modules, combined.

## 0.1.0

### First Changes

-   946b145: First version of core components and modules
    -   FranchiseRegistry
    -   IPAssetRegistry
    -   IPAssetRegistryFactory
    -   Licensing Module
    -   Collect Module
    -   Royalties Module
    -   Relationship Module
    -   Access Control
    -   IP Accounts
