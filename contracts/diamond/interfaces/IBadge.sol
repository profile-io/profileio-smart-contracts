// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBadge {
    function safeMint(
        address _to,
        string memory _tokenURI
    ) external returns (uint256);
}
