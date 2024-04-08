// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./utils/PercentageMath.sol";

contract Badge is ERC721URIStorage {
    using PercentageMath for uint256;

    string public baseTokenURI;

    uint256 public badgeCount;
    uint256 public mintFee; // basis points

    address public creator;

    address constant FEE_COLLECTOR = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    uint256 constant FEE_ROYALTY = 1_000;

    constructor(
        string memory _baseTokenURI,
        string memory _name,
        string memory _symbol,
        uint256 _mintFee,
        address _creator
    )   ERC721(_name, _symbol)
    {
        baseTokenURI = _baseTokenURI;
        mintFee = _mintFee;
        creator = _creator;
    }

    // TODO: Add authorization.
    function mint(
    )   external payable
        returns (bool)
    {
        if (mintFee > 0) {
            // Transfer payment and handle fees.
            require(msg.value == mintFee, 'Insufficient fee');

            // Capture fee.
            (bool sent, ) = payable(FEE_COLLECTOR)
                .call{value: msg.value.percentMul(FEE_ROYALTY)}("");
            require(sent, 'Failed to transfer fee');
            
            // Transfer Ether to Bagde Creator.
            (sent, ) = payable(creator)
                .call{value: msg.value.percentMul(10_000 - FEE_ROYALTY)}("");
            require(sent, 'Failed to transfer fee');
        }

        badgeCount++;
        _safeMint(msg.sender, badgeCount);

        return true;
    }

    // Soulbound MFT functionality.
    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {}
}