// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Modifiers} from "../libs/LibAppStorage.sol";

/**
     ____  ____  ____  _____ _  _     _____   _  ____ 
    /  __\/  __\/  _ \/    // \/ \   /  __/  / \/  _ \
    |  \/||  \/|| / \||  __\| || |   |  \    | || / \|
    |  __/|    /| \_/|| |   | || |_/\|  /_ __| || \_/|
    \_/   \_/\_\\____/\_/   \_/\____/\____\\/\_/\____/

    @author Tabled Technologies Ltd.
    @title  Account Manager Facet
    @notice Admin functions for setting account permissions.
 */

contract AccountManagerFacet is Modifiers {
    function setAdmin(
        address _account,
        uint8 _enabled
    ) external onlyOwner returns (bool) {
        s.isAdmin[_account] = _enabled;
        return true;
    }
    function setBackupOwner(
        address _backupOwner
    ) external onlyOwner returns (bool) {
        s.backupOwner = _backupOwner;
        return true;
    }

    function setFeeCollector(
        address _feeCollector
    ) external onlyOwner returns (bool) {
        s.feeCollector = _feeCollector;
        return true;
    }
}
