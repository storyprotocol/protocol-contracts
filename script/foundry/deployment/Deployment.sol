// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

struct Upgradeable {
    address proxy;
    address implementation;
}

struct RelationshipProcessorsDeployment {
    address permissionless;
    address dstOwner;
    address srcOwner;
    address srcDstOwner;
}

struct MainDeployment {
    address ipAssetsRegistryFactory;
    Upgradeable accessControl;
    Upgradeable franchiseRegistry;
    Upgradeable protocolRelationshipModule;
}
