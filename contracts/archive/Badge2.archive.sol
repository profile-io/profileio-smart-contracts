// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.20;

// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import "@openzeppelin/contracts/access/Ownable2Step.sol";

// contract Badge is ERC721, Ownable2Step {
//     uint256 private _tokenIdCounter;

//     uint8 public authorizedEnabled;

//     address public creator;

//     mapping(address => uint8) authorized;

//     error Unauthorized();

//     /**
//      * @dev Set BadgeManager as initial owner.
//      */
//     constructor(
//         address _owner,
//         address _creator,
//         address[] memory _minters
//     )   ERC721("Profile.io Badge", "BADGE") Ownable(_owner) {
//         creator = _creator;

//         // Enable minting for everyone.
//         if (_minters[0] == address(1)) {
//             return;
//         }
//         for (uint i = 0; i < _minters.length; i++) {
//             authorized[_minters[i]] = 1;
//         }
//         authorizedEnabled = 1;
//     }

//     /// @dev How to account for badgeId?
//     function safeMint(address to) public onlyAuthorized {
//         uint256 tokenId = _tokenIdCounter;
//         _safeMint(to, tokenId);
//         _tokenIdCounter += 1;
//     }

//     function burn(uint256 tokenId) external onlyAuthorized {
//         _burn(tokenId);
//     }

//     /**
//      * @dev Internal function to handle token transfers.
//      * Restricts the transfer of Soulbound tokens.
//      */
//     function _update(
//         address to,
//         uint256 tokenId,
//         address auth
//     )   internal override(ERC721) returns (address) {
//         address from = _ownerOf(tokenId);
//         if (from != address(0) && to != address(0)) {
//             revert("Badge: Transfer failed");
//         }

//         return super._update(to, tokenId, auth);
//     }

//     // function _burn(uint256 tokenId) internal override(ERC721) {
//     //     super._burn(tokenId);
//     // }

//     function setAuthorized(
//         address[] memory _accounts,
//         uint8 _enabled
//     )   external onlyOwner {
//         for (uint i = 0; i < _accounts.length; i++) {
//             authorized[_accounts[i]] = _enabled;
//         }
//     }

//     function setAuthorizedEnabled(
//         uint8 _enabled
//     )   external onlyOwner {

//     }

//     modifier onlyAuthorized() {
//         if (authorizedEnabled == 1) {
//             if (authorized[msg.sender] != 1) {
//                 revert Unauthorized();
//             }
//         }
//         _;
//     }
// }