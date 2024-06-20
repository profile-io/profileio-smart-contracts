// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
     ____  ____  ____  _____ _  _     _____   _  ____ 
    /  __\/  __\/  _ \/    // \/ \   /  __/  / \/  _ \
    |  \/||  \/|| / \||  __\| || |   |  \    | || / \|
    |  __/|    /| \_/|| |   | || |_/\|  /_ __| || \_/|
    \_/   \_/\_\\____/\_/   \_/\____/\____\\/\_/\____/

    @author Tabled Technologies Ltd.
    @title  Badge Manager
    @notice Administratpr functions for setting fees and
            approval of payments.
 */

contract BadgeManager is Ownable2Step {
    address public feeCollector;

    IERC20 public mintPayment;

    uint256 defaultMintFee;

    mapping(address => uint256) mintFee;

    mapping(address => uint8) isBadge;

    constructor(
        address _owner,
        IERC20 _mintPayment,
        uint256 _defaultMintFee
    )   Ownable(_owner)
    {
        feeCollector = _owner;
        mintPayment = _mintPayment;
        defaultMintFee = _defaultMintFee;
    }

    /*//////////////////////////////////////////////////////////////
                            BADGE PAYMENT
    //////////////////////////////////////////////////////////////*/

    function transferMintPayment(
        address _from
    )   external onlyBadge
        returns (bool)
    {
        // Ensure _from account has provided approval first.
        SafeERC20.safeTransferFrom(
            mintPayment,
            _from,
            feeCollector,
            getMintFee(msg.sender)
        );
        return true;
    }

    /// @dev Use to check against the allowance prior to minting Badge.
    function getMintFee(
        address _badge
    )   public view
        returns (uint256)
    {
        // If custom mintFee has been set for the Badge use that, otherwise use default.
        return mintFee[_badge] == 0 ? defaultMintFee : mintFee[_badge];
    }

    /*//////////////////////////////////////////////////////////////
                                ADMIN
    //////////////////////////////////////////////////////////////*/

    /// @dev Sets the address provided as a Badge contract. Calls made from that
    /// address will therefore enable the mint payment to be executed.
    function setBadge(
        address _badge,
        uint8 _active
    )   external onlyOwner
    {
        isBadge[_badge] = _active;
    }

    function setMintPayment(
        IERC20 _mintPayment
    )   external onlyOwner
    {
        mintPayment = _mintPayment;
    }

    /// @notice Sets a custom mint fee for the given Badge.
    /// @dev Setting to 0 will then use the default mint fee.
    function setMintFee(
        address _badge,
        uint256 _mintFee
    )   external onlyOwner
    {
        mintFee[_badge] = _mintFee;
    }

    function setDefaultMintFee(
        uint256 _defaultMintFee
    )   external onlyOwner
    {
        defaultMintFee = _defaultMintFee;
    }

    function setFeeCollector(
        address _feeCollector
    )   external onlyOwner
    {
        feeCollector = _feeCollector;
    }

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyBadge() {
        require(isBadge[msg.sender] == 1, "BadgeManager: Caller not Badge contract");
        _;
    }
}