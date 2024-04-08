// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IBadgeFactory {

    function createBadge(
        string memory _baseTokenURI,
        string memory _name,
        string memory _symbol,
        uint256       _mintFee,
        address       _owner
    )   external 
        returns (address);
}