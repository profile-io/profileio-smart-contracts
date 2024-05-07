// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "./interfaces/IBadgeManager.sol";

/**
     ____  ____  ____  _____ _  _     _____   _  ____ 
    /  __\/  __\/  _ \/    // \/ \   /  __/  / \/  _ \
    |  \/||  \/|| / \||  __\| || |   |  \    | || / \|
    |  __/|    /| \_/|| |   | || |_/\|  /_ __| || \_/|
    \_/   \_/\_\\____/\_/   \_/\____/\____\\/\_/\____/

    @author Sam Goodenough, Tabled Technologies Ltd.
    @title  Badge
    @notice Soul-bound NFT Badge Contract issued by Profile.io.
 */

contract Badge is ERC721URIStorage, Ownable2Step {
    uint256 private _tokenIdCounter;

    IBadgeManager badgeManager;

    /// @dev We know the owner of the tokenId by calling ownerOf().
    // E.g., tokenId => endorsements: [Bob, Charlie, Dave, ...].
    mapping(uint256 => address[]) public endorsements;

    /// @dev Enables quick verification of checking endorsement.
    // E.g., Bob => tokenId => Y.
    mapping(address => mapping(uint256 => uint8)) public endorsed;

    error EndorsementNotFound();

    /**
     * @param _owner The initial owner of the NFT contract.
     * @param _badgeManager The Badge Manager contract.
     */
    constructor(
        address _owner,
        IBadgeManager _badgeManager
    )   ERC721("Profile.io Badge", "BADGE") Ownable(_owner)
    {
        badgeManager = _badgeManager;
    }

    /*//////////////////////////////////////////////////////////////
                            BADGE MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Returns the tokenId which should be stored locally.
     * @dev Will fail if minter has not provided approval.
     * @param to The account to mint the Badge to.
     * @param payer The account responsible for the mint fee.
     * @param _tokenURI Pointer to the metadata for the tokenId to be minted.
     */
    function safeMint(
        address to,
        address payer,
        string memory _tokenURI
    )   public onlyOwner
        returns (uint256 tokenId)
    {
        badgeManager.transferMintPayment(payer);

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
    )   internal override(ERC721)
        returns (address)
    {
        address from = _ownerOf(tokenId);
        if (from != address(0) && to != address(0)) {
            revert("Badge: Transfer failed");
        }

        return super._update(to, tokenId, auth);
    }

    function burn(
        uint256 tokenId
    )   external onlyOwner
    {
        _burn(tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                            ENDORSEMENTS
    //////////////////////////////////////////////////////////////*/

    /// @return total The new total number of endorsements for the provided tokenId.
    function endorse(
        uint256 tokenId
    )   external
        returns (uint256 total)
    {
        endorsements[tokenId].push(msg.sender);
        endorsed[msg.sender][tokenId] = 1;
        return endorsements[tokenId].length;
    }

    /// @return total The new total number of endorsements for the provided tokenId.
    function revokeEndorsement(
        uint256 tokenId
    )   external
        returns (uint256 total)
    {
        for (uint i = 0; i < endorsements[tokenId].length; i++) {
            if (endorsements[tokenId][i] == msg.sender) {
                endorsements[tokenId][i] =
                    endorsements[tokenId][endorsements[tokenId].length - 1];
                endorsements[tokenId].pop();
                return endorsements[tokenId].length;
            }
        }
        revert EndorsementNotFound();
    }

    function getEndorsementsTotal(
        uint256 tokenId
    )   external view
        returns (uint256)
    {
        return endorsements[tokenId].length;
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
    )   external onlyOwner
    {
        _requireOwned(tokenId);
        _setTokenURI(tokenId, _tokenURI);
    }
}