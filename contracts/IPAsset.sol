// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

enum IPAsset {
    UNDEFINED,
    STORY,
    CHARACTER,
    ART,
    GROUP,
    LOCATION,
    ITEM
}

uint8 constant EXTERNAL_ASSET = type(uint8).max;
