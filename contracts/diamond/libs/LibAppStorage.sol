// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* Diamond specific */
import {LibDiamond} from ".././core/libs/LibDiamond.sol";
/* --- END Diamond specific --- */

struct BadgeParams {
    CustomMintParams customMintParams;
    uint8 mintEnabled;
    uint8 endorsementEnabled;
}

struct CustomMintParams {
    uint256 mintFee;
    address mintPayment;    // ex: USDC contract address, WETH contract address, 
    uint8 enabled;
}

enum EndorsementStatus {
    NotSet,
    Endorsed,
    Revoked
}

/// @dev Instance of an endorsement.
struct EndorsementInfo {
    uint256 timestamp; // Timestamp of the most recent status update.
    address sender;
    EndorsementStatus status;
}

struct AppStorage {
    /*//////////////////////////////////////////////////////////////
                            BADGE MANAGEMENT V1
    //////////////////////////////////////////////////////////////*/
    // The default mint fee.
    uint256 defaultMintFee;
    // If enabled, uses values set instead of the default.
    mapping(address => CustomMintParams) customMintParams;
    // The default ERC20 token used for mint payment.
    address defaultMintPayment;
    // E.g., Badge contract => BadgeParams.
    mapping(address => BadgeParams) badgeParams;

    /*//////////////////////////////////////////////////////////////
                            ENDORSEMENTS V1
    //////////////////////////////////////////////////////////////*/
    /// @dev We know the owner of the tokenId by calling ownerOf().
    /// @dev Can only push to this array when endorsing.
    // NFT Address => tokenId => [endorsement1, endorsement2, ...]
    mapping(address => mapping(uint256 => EndorsementInfo[])) endorsementInfo;
    // E.g., Alice => (NFT address + tokenId) => index in endorsement info array.
    mapping(address => mapping(uint256 => uint256)) endorsementInfoIndex;
    // NFT Address => tokenId => total number of revoked endorsements.
    mapping(address => mapping(uint256 => uint256)) revoked;

    /*//////////////////////////////////////////////////////////////
                        ACCOUNT MANAGEMENT V1
    //////////////////////////////////////////////////////////////*/
    address owner;
    address backupOwner;
    mapping(address => uint8) isAdmin;
    address controller;
    address feeCollector;
    uint8 reentrantStatus;

    /* Add new V2 storage here */
    // Keep in mind that even if you delete a facet, storage variable will remaining. DO NOT DELETE variables here
}

/* -- Diamond specific --- */
library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        // bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := 0
        }
    }

    function abs(int256 x_) internal pure returns (uint256) {
        return uint256(x_ >= 0 ? x_ : -x_);
    }
}
/* -- END --- */

contract Modifiers {
    AppStorage internal s;

    modifier onlyController() {
        require(
            s.controller == msg.sender,
            "Caller not controller"
        );
        _;
    }

    modifier onlyAdmin() {
        require(s.isAdmin[msg.sender] == 1, "Caller not admin");
        _;
    }

    modifier onlyOwner() {
        require(
            s.owner == msg.sender || s.backupOwner == msg.sender,
            "Caller not owner"
        );
        _;
    }

    modifier nonReentrant() {
        require(s.reentrantStatus != 2, "Reentrant call");
        s.reentrantStatus = 2;
        _;
        s.reentrantStatus = 1;
    }
}
