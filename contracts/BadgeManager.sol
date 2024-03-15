// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/IBadgeFactory.sol";

contract BadgeManager {

    IBadgeFactory badgeFactory;

    mapping(address => bool) authorized;

    uint256 creationFee;

    error InsufficientFee();

    constructor(
        IBadgeFactory _badgeFactory
    )
    {
        badgeFactory = _badgeFactory;
        authorized[msg.sender] = true;
    }

    function createBadge(
        string memory _creatorDID,
        string memory _baseTokenURI,
        string memory _name,
        string memory _symbol,
        uint256 _mintFee,
        address _owner
    )   external payable onlyAuthorized
        returns (address)
    {
        if (msg.value != creationFee) {
            revert InsufficientFee();
        }

        return badgeFactory.createBadge(
            _creatorDID,
            _baseTokenURI,
            _name,
            _symbol,
            _mintFee,
            _owner
        );
    }

    modifier onlyAuthorized() {
        require(authorized[msg.sender] == true, 'Caller not authorized');
        _;
    }
}