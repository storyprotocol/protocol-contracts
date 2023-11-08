// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

library Licensing {

    struct License {
        string termsPlaceholder;
    }

    bytes32 public constant IPORG_TERMS_CONFIG = keccak256("IPORG_TERMS_CONFIG");


}
