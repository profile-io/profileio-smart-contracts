// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract Badge is ERC721URIStorage, Ownable2Step {
    uint256 private _tokenIdCounter;

    /// @dev We know the owner of the tokenId by calling ownerOf().
    // E.g., tokenId => endorsements: [Bob, Charlie, Dave, ...].
    mapping(uint256 => address[]) public endorsements;

    /// @dev Enables quick verification of checking endorsement.
    // E.g., Bob => tokenId => Y.
    mapping(address => mapping(uint256 => uint8)) public endorsed;

    mapping(uint256 => string) pointer;

    uint256 public mintFee;

    IERC20 public mintPayment;

    address public feeCollector;

    error EndorsementNotFound();

    /**
     * @param _owner The initial owner of the NFT contract.
     * @param _mintPayment The ERC20 token used for payment.
     * @param _mintFee The payment amount.
     */
    constructor(
        address _owner,
        IERC20 _mintPayment,
        uint256 _mintFee
    )   ERC721("Profile.io Badge", "BADGE") Ownable(_owner)
    {
        feeCollector = _owner;
        mintPayment = _mintPayment;
        mintFee = _mintFee;
    }

    /*//////////////////////////////////////////////////////////////
                            TOKEN MANAGEMENT
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
        if (mintFee > 0) {
            // Transfer mint fee to fee collector.
            SafeERC20.safeTransferFrom(
                mintPayment, // The ERC20 token used for payment.
                payer, // The account making the payment.
                owner(), // The account receiving the fee.
                mintFee // The mint fee being paid in wei.
            );
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

    function endorse(
        uint256 tokenId
    )   external
        returns (uint256)
    {
        endorsements[tokenId].push(msg.sender);
        endorsed[msg.sender][tokenId] = 1;
        return endorsements[tokenId].length;
    }

    function revokeEndorsement(
        uint256 tokenId
    )   external
        returns (uint256)
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
     * Useful if the API endpoint has been modified on the backend.
     */
    function setTokenURI(
        uint256 tokenId,
        string memory _tokenURI
    )   external onlyOwner
    {
        _requireOwned(tokenId);
        _setTokenURI(tokenId, _tokenURI);
    }

    function setMintPayment(
        IERC20 _mintPayment
    )   external onlyOwner
    {
        mintPayment = _mintPayment;
    }

    function setMintFee(
        uint256 _mintFee
    )   external onlyOwner
    {
        mintFee = _mintFee;
    }

    function setFeeCollector(
        address _feeCollector
    )   external onlyOwner
    {
        feeCollector = _feeCollector;
    }
}