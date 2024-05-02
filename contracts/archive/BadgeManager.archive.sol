// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.20;

// import "./interfaces/IBadgeFactory.sol";

// contract BadgeManager {

//     IBadgeFactory badgeFactory;

//     mapping(address => bool) authorized;

//     uint256 creationFee;

//     error InvalidFee();

//     constructor(
//         IBadgeFactory _badgeFactory
//     )
//     {
//         badgeFactory = _badgeFactory;
//         authorized[msg.sender] = true;
//     }

//     function create(
//         string memory _baseTokenURI,
//         string memory _name,
//         string memory _symbol,
//         uint256 _mintFee,
//         address _owner
//     )   external payable onlyAuthorized
//         returns (address)
//     {
//         if (msg.value != creationFee) {
//             revert InvalidFee();
//         }

//         return badgeFactory.createBadge(
//             _baseTokenURI,
//             _name,
//             _symbol,
//             _mintFee,
//             _owner
//         );
//     }

//     modifier onlyAuthorized() {
//         require(authorized[msg.sender] == true, 'Caller not authorized');
//         _;
//     }

//     // function issueBadge

//     // function setMinter(
//     //     address[] memory accounts,
//     //     bool active
//     // ) {
        
//     // }
// }