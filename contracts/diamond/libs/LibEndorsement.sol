// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AppStorage} from "./LibAppStorage.sol";

library LibEndorsement {
    event Endorsed(address indexed sender, uint256 indexed tokenId);
    event Revoked(address indexed sender, uint256 indexed tokenId);
}