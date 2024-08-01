// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AppStorage} from "./LibAppStorage.sol";

/* When to use a Library
    - When you have multiple Factes that share the same functionality.
    - Defining Events.
*/


library LibEndorsement {
    event Endorsed(address indexed sender, address indexed badge, uint256 indexed tokenId);
    event Revoked(address indexed sender, address indexed badge, uint256 indexed tokenId);
}