---
name: Add Link template
about: Propose a new relationships between SP entities.
title: 'Add Link: <LINK_NAME>'
labels: SPIP
assignees: ''

---

- **Name**: Link name
- **LinkId**: how to obtain the bytes32 identifier that will be use in the contract, usually `keccak256(<LINK_NAME>)`
- **Scope**: Protocol (available to all franchises by default) Franchise (per franchise opt in)
- **Source**: Which (address, id) pair can be the source of the link

| External | STORY | CHARACTER | ART | GROUP | LOCATION | ITEM |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: |
|  |  |  |  |  |  |  |

- **Destination**: Which (address, id) can be the destination of the link

| External | STORY | CHARACTER | ART | GROUP | LOCATION | ITEM |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: |
|  |  |  |  |  |  |  |

- **Can link other franchises**: True or False.

- **Criteria**:

A description of what the link IS and IS NOT. Ideally this is legally compliant, or at least EIP level of standard definition and clear language. 

This text will be the basis for link removal dispute resolution and help scope the implementation.

- **Processing Logic**:
    
Define the logic that has to run correctly before creating the relationship. This include detailing what permissions must the link requester have (for example owning the source and/or destination NFTs, being the owner of the Franchise NFT, having a protocol level role...), request/response flows, multi step or multisig processes, ERC20 payments...

The Processor module in the next section will be the contract in charge of enforcing these.
    
- **Processor Module**: 

Detailed enumeration of the modules that we need to execute correctly before the link is created, for example payment modules. Links to the code and/or address of deployed modules implementing the processing logic.

- **Side Effects and interactions**:

Detailed description of the effects of the link creation. They could be interaction with another modules or even implicit side effects (for example, transfer restrictions, NFT minting like Autograph, License NFT…, Inclusion in royalties, Off chain license implications…)
