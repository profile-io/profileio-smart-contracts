// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.20;

// import "./Badge.sol";

// contract BadgeFactory {

//     mapping(address => bool) authorized;

//     event BadgeContractDeployed(address _badge);

//     constructor() {
//         authorized[msg.sender] = true;
//     }

//     // /**
//     //  * @param _baseTokenURI The URI of the Badge data with tokenId omitted
//     //  * (e.g., https://api.pudgypenguins.io/lil/<tokenId>).
//     //  * @param _name The name of the Badge (e.g., Certified Python Developer).
//     //  * @param _symbol The symbol of the Badge (e.g., CPD).
//     //  * @param _mintFee The fee to mint the badge (can be zero).
//     //  * @param _owner The owner of the newly deployed Badge contract (can amend fee, revoke, etc.).
//     //  */
//     // function create(
//     //     string memory _baseTokenURI,
//     //     string memory _name,
//     //     string memory _symbol,
//     //     uint256 _mintFee,
//     //     address _owner
//     // )   external onlyAuthorized
//     //     returns (address)
//     // {
//     //     Badge badge = new Badge(
//     //         _baseTokenURI,
//     //         _name,
//     //         _symbol,
//     //         _mintFee,
//     //         _owner
//     //     );
//     //     emit BadgeContractDeployed(address(badge));
//     //     return address(badge);
//     // }

//     modifier onlyAuthorized() {
//         require(authorized[msg.sender] == true, 'Caller not authorized');
//         _;
//     }
// }