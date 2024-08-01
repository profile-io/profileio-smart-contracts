// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./BadgeV2.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

/**
     ____  ____  ____  _____ _  _     _____   _  ____ 
    /  __\/  __\/  _ \/    // \/ \   /  __/  / \/  _ \
    |  \/||  \/|| / \||  __\| || |   |  \    | || / \|
    |  __/|    /| \_/|| |   | || |_/\|  /_ __| || \_/|
    \_/   \_/\_\\____/\_/   \_/\____/\____\\/\_/\____/

    @author Tabled Technologies Ltd.
    @title  Badge V2 Factory
    @notice Factory for creating BadgeV2 contracts.
 */

contract BadgeV2Factory is Ownable2Step {
    BadgeV2[] public badgeArray;

    event BadgeV2Created(address indexed badge, address indexed owner);

    address public diamond;

    constructor(address _owner, address _diamond) Ownable(_owner) {
        diamond = _diamond;
    }

    function createBadge() external onlyOwner returns (address) {
        BadgeV2 badge = new BadgeV2(owner(), diamond);
        badgeArray.push(badge);
        emit BadgeV2Created(address(badge), owner());
        return address(badge);
    }
}
