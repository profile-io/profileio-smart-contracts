// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BadgeParams, CustomMintParams, EndorsementInfo, EndorsementStatus, Modifiers} from "../libs/LibAppStorage.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IBadge.sol";

/**
     ____  ____  ____  _____ _  _     _____   _  ____ 
    /  __\/  __\/  _ \/    // \/ \   /  __/  / \/  _ \
    |  \/||  \/|| / \||  __\| || |   |  \    | || / \|
    |  __/|    /| \_/|| |   | || |_/\|  /_ __| || \_/|
    \_/   \_/\_\\____/\_/   \_/\____/\____\\/\_/\____/

    @author Tabled Technologies Ltd.
    @title  Badge Manager
    @notice Administrator functions for issuing Badges.
 */

contract BadgeManagerFacet is Modifiers {
    using SafeERC20 for IERC20;

    /**
     * @notice Mints a Badge to the provided address.
     * @dev Enforcing minter privileges is handled by the back-end.
     * @param _badge The Badge contract to mint.
     * @param _payer The account to take payment from (address(0) if subsidised).
     * @param _to The account to mint the Badge to.
     * @param _tokenURI Metadata for the Badge.
     * @return tokenId The tokenId of the minted Badge.
     */
    function mint(
        address _badge,
        address _payer,
        address _to,
        string memory _tokenURI
    ) external onlyController nonReentrant returns (uint256 tokenId) {
        require(
            s.badgeParams[_badge].mintEnabled == 1,
            "BadgeManagerFacet: Minting disabled for Badge"
        );

        // Handle the mint payment if applicable.
        // the below case is "non-subsidy case"
        if (_payer != address(0)) {
            address mintPayment = s.defaultMintPayment;
            uint256 mintFee = s.defaultMintFee;
            if (s.badgeParams[_badge].customMintParams.enabled == 1) {
                // In case, badge creator selected other than USDC contract (ex: WETH contract 0.1 ETH instead of 0.5 USDC)
                mintPayment = s
                    .badgeParams[_badge]
                    .customMintParams
                    .mintPayment;
                mintFee = s.badgeParams[_badge].customMintParams.mintFee;
            }
            require(mintFee > 0, "BadgeManagerFacet: Mint fee not set");
            SafeERC20.safeTransferFrom(
                IERC20(mintPayment),
                _payer,
                s.feeCollector,
                mintFee
            );
        }

        // Mint the Badge
        tokenId = IBadge(_badge).safeMint(_to, _tokenURI);

        // Instantiate the endorsementInfo array.
        EndorsementInfo memory endorsement = EndorsementInfo({
            timestamp: block.timestamp,
            sender: _to,
            status: EndorsementStatus(1)
        });
        s.endorsementInfo[_badge][tokenId].push(endorsement);
    }

    /*//////////////////////////////////////////////////////////////
                            ADMIN - SETTERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets a custom mint fee for the given Badge.
    function setCustomMintParams(
        address _badge,
        uint256 mintFee,
        address mintPayment,
        uint8 enabled
    ) external onlyAdmin returns (bool) {
        s.customMintParams[_badge] = CustomMintParams({
            mintFee: mintFee,
            mintPayment: mintPayment,
            enabled: enabled
        });
        return true;
    }

    function setDefaultMintFee(
        uint256 _defaultMintFee
    ) external onlyAdmin returns (bool) {
        s.defaultMintFee = _defaultMintFee;
        return true;
    }

    function setDefaultMintPayment(
        address _defaultMintPayment
    ) external onlyAdmin returns (bool) {
        s.defaultMintPayment = _defaultMintPayment;
        return true;
    }

    /// @dev Need to enable a Badge for minting.
    function setMintEnabled(
        address _badge,
        uint8 _enabled
    ) external onlyAdmin returns (bool) {
        s.badgeParams[_badge].mintEnabled = _enabled;
        return true;
    }

    /// @dev Need to enable a Badge for minting.
    function setEndorsementEnabled(
        address _badge,
        uint8 _enabled
    ) external onlyAdmin returns (bool) {
        s.badgeParams[_badge].endorsementEnabled = _enabled;
        return true;
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    function getBadgeParams(
        address _badge
    ) external view returns (BadgeParams memory) {
        return s.badgeParams[_badge];
    }

    /// @dev Use to check against the allowance prior to minting Badge.
    function getMintParams(
        address _badge
    ) public view returns (address, uint256) {
        if (s.customMintParams[_badge].enabled == 1) {
            return (
                s.customMintParams[_badge].mintPayment,
                s.customMintParams[_badge].mintFee
            );
        }
        return (s.defaultMintPayment, s.defaultMintFee);
    }

    function getDefaultMintFee() external view returns (uint256) {
        return s.defaultMintFee;
    }

    function getDefaultMintPayment() external view returns (address) {
        return s.defaultMintPayment;
    }

    function getMintEnabled(address _badge) external view returns (uint8) {
        return s.badgeParams[_badge].mintEnabled;
    }

    function getEndorsementEnabled(
        address _badge
    ) external view returns (uint8) {
        return s.badgeParams[_badge].endorsementEnabled;
    }
}
