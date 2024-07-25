// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "./core/libs/LibDiamond.sol";
import {IERC165} from "./core/interfaces/IERC165.sol";
import {IDiamondCut} from "./core/interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "./core/interfaces/IDiamondLoupe.sol";
import {IERC173} from "./core/interfaces/IERC173.sol";
import {AppStorage} from "./libs/LibAppStorage.sol";

contract InitDiamond {
    AppStorage internal s;

    struct Args {
        // msg.sender is Admin by default, so do not need to include.
        address defaultMintPayment;
        uint256 defaultMintFee;
        address[] roles;
    }

    function init(Args memory _args) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        // Adding ERC165 data.
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;

        s.defaultMintPayment = _args.defaultMintPayment;
        s.defaultMintFee = _args.defaultMintFee;

        // Set roles.
        s.owner = msg.sender;
        s.isAdmin[msg.sender] = 1;
        s.backupOwner = _args.roles[0];
        s.isAdmin[_args.roles[0]] = 1;
        s.controller = msg.sender;
        s.feeCollector = _args.roles[1];
    }
}