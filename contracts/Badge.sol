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

    @author Tabled Technologies Ltd.
    @title  Badge
    @notice Soul-bound NFT Badge Contract issued by Profile.io.
 */

contract Badge is ERC721URIStorage, Ownable2Step {
    uint256 private _tokenIdCounter;

    IBadgeManager badgeManager;

    /// @dev We know the owner of the tokenId by calling ownerOf().
    /// @dev Can only push to this array when edorsing.
    mapping(uint256 => EndorsementInfo[]) public endorsementInfo;

    /// @dev Used to help keep track of total number of endorsements for a given tokenId.
    mapping(uint256 => uint256) private revoked;

    /// @dev Enables quick verification of checking endorsement.
    mapping(address => mapping(uint256 => uint256)) public endorsementInfoIndex;

    enum EndorsementStatus {
        NotSet,
        Endorsed,
        Revoked
    }

    struct EndorsementInfo {
        uint256 timestamp; // Timestamp of the most recent status update.
        // uint256 index; // Index in endorsementState array.
        address sender;
        EndorsementStatus status;
    }

    event Endorsed(address indexed sender, uint256 indexed tokenId);
    event Revoked(address indexed sender, uint256 indexed tokenId);

    /**
     * @param _owner The initial owner of the NFT contract.
     * @param _badgeManager The Badge Manager contract.
     */
    constructor(
        address _owner,
        IBadgeManager _badgeManager
    ) ERC721("Profile.io Badge", "BADGE") Ownable(_owner) {
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
    ) public onlyOwner returns (uint256 tokenId) {
        // To subsidise mint, set payer to address(0).
        if (payer != address(0)) {
            badgeManager.transferMintPayment(payer);
        }

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
                            ENDORSEMENTS
    //////////////////////////////////////////////////////////////*/

    /// @return total The new total number of endorsements for the provided tokenId.
    function endorse(uint256 tokenId) external returns (uint256 total) {
        require(
            ownerOf(tokenId) != msg.sender,
            "Badge: Cannot endorse own badge"
        );

        EndorsementInfo memory endorsement = checkEndorsementInfo(msg.sender, tokenId);

        if (endorsement.status == EndorsementStatus(0)) {
            return _endorse(tokenId);
        } else if (endorsement.status == EndorsementStatus(2)) {
            return _endorseUpdate(tokenId);
        } else {
            revert ("Badge: Already endorsed");
        }
    }

    /// @dev NotSet => Endorsed.
    function _endorse(uint256 tokenId) internal returns (uint256 total) {
        EndorsementInfo memory endorsement = EndorsementInfo({
            timestamp: block.timestamp,
            sender: msg.sender,
            status: EndorsementStatus(1)
        });

        endorsementInfoIndex[msg.sender][tokenId] = endorsementInfo[tokenId].length;
        endorsementInfo[tokenId].push(endorsement);

        emit Endorsed(msg.sender, tokenId);
        return endorsementInfo[tokenId].length - revoked[tokenId];
    }

    /// @dev Revoked => Endorsed.
    function _endorseUpdate(uint256 tokenId) internal returns (uint256 total) {
        uint i = endorsementInfoIndex[msg.sender][tokenId];

        endorsementInfo[tokenId][i].timestamp = block.timestamp;
        endorsementInfo[tokenId][i].status = EndorsementStatus(1);

        revoked[tokenId] -= 1;

        emit Endorsed(msg.sender, tokenId);
        return endorsementInfo[tokenId].length - revoked[tokenId];
    }

    /// @return total The new total number of endorsements for the provided tokenId.
    function revokeEndorsement(
        uint256 tokenId
    ) external returns (uint256 total) {
        uint i = endorsementInfoIndex[msg.sender][tokenId];

        require(
            endorsementInfo[tokenId][i].sender == msg.sender,
            "Badge: Sender mismatch"
        );
        require(
            endorsementInfo[tokenId][i].status == EndorsementStatus(1),
            "Badge: Not endorsed"
        );

        endorsementInfo[tokenId][i].timestamp = block.timestamp;
        endorsementInfo[tokenId][i].status = EndorsementStatus(2);
        revoked[tokenId] += 1;
        emit Revoked(msg.sender, tokenId);
        return endorsementInfo[tokenId].length - revoked[tokenId];
    }

    function checkEndorsementInfo(
        address sender,
        uint256 tokenId
    ) public view returns (EndorsementInfo memory endorsement) {
        uint i = endorsementInfoIndex[msg.sender][tokenId];

        /// @dev Index default is 0.
        if (endorsementInfo[tokenId][i].sender != sender) {
            return endorsement;
        }
        return endorsementInfo[tokenId][i];
    }

    function getEndorsementsTotal(
        uint256 tokenId
    ) external view returns (uint256) {
        return endorsementInfo[tokenId].length  - revoked[tokenId];
    }

    function getEndorsementInfoTotal(
        uint256 tokenId
    ) external view returns (uint256) {
        return endorsementInfo[tokenId].length;
    }

    function getEndorsements(
        uint256 tokenId
    ) external view returns (EndorsementInfo[] memory) {
        return endorsementInfo[tokenId];
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
        _requireOwned(tokenId);
        _setTokenURI(tokenId, _tokenURI);
    }
}
