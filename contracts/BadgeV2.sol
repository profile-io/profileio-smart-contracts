// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

/**
     ____  ____  ____  _____ _  _     _____   _  ____ 
    /  __\/  __\/  _ \/    // \/ \   /  __/  / \/  _ \
    |  \/||  \/|| / \||  __\| || |   |  \    | || / \|
    |  __/|    /| \_/|| |   | || |_/\|  /_ __| || \_/|
    \_/   \_/\_\\____/\_/   \_/\____/\____\\/\_/\____/

    @author Tabled Technologies Ltd.
    @title  BadgeV2
    @notice Soul-bound NFT Badge Contract issued by Profile.io.
 */

contract BadgeV2 is ERC721URIStorage, Ownable2Step {
    uint256 private _tokenIdCounter;

    mapping(address => uint8) authorized;

    constructor(
        address _owner,
        address _diamond
    ) ERC721("Profile.io Badge", "BADGE") Ownable(_owner) {
        authorized[_owner] = 1;
        authorized[_diamond] = 1;
    }

    /*//////////////////////////////////////////////////////////////
                            BADGE MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Returns the tokenId which should be stored locally.
     * @dev Will fail if minter has not provided approval.
     * @param to The account to mint the Badge to.
     * @param _tokenURI Pointer to the metadata for the tokenId to be minted.
     */
    function safeMint(
        address to,
        string memory _tokenURI
    ) public onlyAuthorized returns (uint256 tokenId) {
        // Store tokenId locally in database.
        tokenId = _tokenIdCounter;
        _setTokenURI(tokenId, _tokenURI);
        _safeMint(to, tokenId);

        _tokenIdCounter += 1;
    }

    /**
     * @dev Internal function to handle token transfers.
     * Restricts the transfer of Soulbound tokens.
     */
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721) returns (address) {
        address from = _ownerOf(tokenId);
        if (from != address(0) && to != address(0)) {
            revert("Badge: Transfer failed");
        }

        return super._update(to, tokenId, auth);
    }

    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                                ADMIN
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Enables owner to manually set the tokenURI for a given tokenId.
     * Useful if the API endpoint has been modified.
     */
    function setTokenURI(
        uint256 tokenId,
        string memory _tokenURI
    ) external onlyOwner {
        // Requires that the tokenId has an owner.
        _requireOwned(tokenId);
        _setTokenURI(tokenId, _tokenURI);
    }

    function setAuthorized(
        address _auth,
        uint8 _status
    ) external onlyOwner {
        authorized[_auth] = _status;
    }

    modifier onlyAuthorized() {
        require(authorized[msg.sender] == 1, "Badge: Caller not authorized");
        _;
    }
}
