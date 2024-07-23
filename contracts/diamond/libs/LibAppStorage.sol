// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from ".././core/libs/LibDiamond.sol";

struct BadgeParams {
    CustomMintParams customMintParams;
    uint8 mintEnabled;
}

struct CustomMintParams {
    uint256 mintFee;
    address mintPayment;
    uint8 enabled;
}

enum EndorsementStatus {
    NotSet,
    Endorsed,
    Revoked
}

struct EndorsementInfo {
    uint256 timestamp; // Timestamp of the most recent status update.
    address sender;
    EndorsementStatus status;
}

struct EndorsementsInfo {
    address badge;
    uint256 tokenId;
    uint256 index;
}

struct AppStorage {
    // The default mint fee.
    uint256 defaultMintFee;
    // If enabled, uses values set instead of the default.
    mapping(address => CustomMintParams) customMintParams;
    // The default ERC20 token used for mint payment.
    address defaultMintPayment;

    mapping(address => BadgeParams) badgeParams;

    /// @dev We know the owner of the tokenId by calling ownerOf().
    /// @dev Can only push to this array when endorsing.
    // E.g., Badge contract 0x1234... => tokenId 7 => [endorsement1, endorsement2, ...]
    mapping(address => mapping(uint256 => EndorsementInfo[])) endorsementInfo;

    // STRUCT(?) //


    /// @dev Used to help keep track of total number of endorsements for a given tokenId.
    // E.g., Badge contract 0x1234... => tokenId 7 => 3.
    mapping(address => mapping(uint256 => uint256)) revoked;

    /// @dev Enables quick verification of checking endorsement.
    // E.g., 0x1234 ("Endorser/Sender") => tokenId 7 => index 21.
    mapping(address => mapping(uint256 => uint256)) endorsementInfoIndex;

    mapping(address => mapping(address => uint256)) endorsementCount;

    address owner;
    address backupOwner;
    mapping(address => uint8) isAdmin;
    address controller;
    address feeCollector;
    uint8 reentrantStatus;

    address nftFactory;
    //
    
}

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
