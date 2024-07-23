// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {EndorsementStatus, EndorsementInfo, Modifiers} from "../libs/LibAppStorage.sol";
import {LibEndorsement} from "../libs/LibEndorsement.sol";

/**
     ____  ____  ____  _____ _  _     _____   _  ____ 
    /  __\/  __\/  _ \/    // \/ \   /  __/  / \/  _ \
    |  \/||  \/|| / \||  __\| || |   |  \    | || / \|
    |  __/|    /| \_/|| |   | || |_/\|  /_ __| || \_/|
    \_/   \_/\_\\____/\_/   \_/\____/\____\\/\_/\____/

    @author Tabled Technologies Ltd.
    @title  Badge Endorsement Facet
    @notice Functions for handling Badge endorsements.
 */

contract BadgeEndorsementFacet is Modifiers {
    
    /// @return total The new total number of endorsements for the provided tokenId.
    function endorse(
        IERC721 _badge,
        uint256 tokenId
    ) external returns (uint256 total) {
        require(s.isBadge[_badge], "Badge: Invalid badge contract");
        require(
            _badge.ownerOf(tokenId) != msg.sender,
            "Badge: Cannot endorse own badge"
        );

        EndorsementInfo memory endorsement = checkEndorsementInfo(
            msg.sender,
            tokenId
        );

        if (endorsement.status == EndorsementStatus(0)) {
            return _endorse(tokenId);
        } else if (endorsement.status == EndorsementStatus(2)) {
            return _endorseUpdate(tokenId);
        } else {
            revert("Badge: Already endorsed");
        }
    }

    /// @dev NotSet => Endorsed.
    function _endorse(uint256 tokenId) internal returns (uint256 total) {
        EndorsementInfo memory endorsement = EndorsementInfo({
            timestamp: block.timestamp,
            sender: msg.sender,
            status: EndorsementStatus(1)
        });

        s.endorsementInfoIndex[msg.sender][tokenId] = s.endorsementInfo[tokenId]
            .length;
        s.endorsementInfo[tokenId].push(endorsement);

        emit LibEndorsement.Endorsed(msg.sender, tokenId);
        return s.endorsementInfo[tokenId].length - s.revoked[tokenId];
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
        require(
            ownerOf(tokenId) != msg.sender,
            "Badge: Cannot revoke endorsement of own badge"
        );

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

    /// @notice Returns the endorsement info for a given tokenId.
    function checkEndorsementInfo(
        address sender,
        uint256 tokenId
    ) public view returns (EndorsementInfo memory endorsement) {
        uint i = endorsementInfoIndex[sender][tokenId];

        /// @dev Index 0 will always be the tokenId owner.
        if (i == 0) {
            return endorsement;
        }
        return endorsementInfo[tokenId][i];
    }

    /// @notice Returns the actual number of endorsements for a given tokenId.
    function getEndorsementsTotal(
        uint256 tokenId
    ) external view returns (uint256) {
        if (endorsementInfo[tokenId].length == revoked[tokenId]) {
            return 0;
        }
        return endorsementInfo[tokenId].length - (1 + revoked[tokenId]);
    }

    /// @notice Includes revoked endorsements.
    function getEndorsementInfoTotal(
        uint256 tokenId
    ) external view returns (uint256) {
        if (endorsementInfo[tokenId].length == 0) {
            return 0;
        }
        return endorsementInfo[tokenId].length - 1;
    }

    function getEndorsements(
        uint256 tokenId
    ) external view returns (EndorsementInfo[] memory) {
        return endorsementInfo[tokenId];
    }

    function get20Endorsements(
        uint256 tokenId,
        uint256 offset,
        bool skipRevoked
    ) external view returns (EndorsementInfo[20] memory endorsements) {
        uint j;
        if (endorsementInfo[tokenId].length - 1 < offset) {
            return endorsements;
        }
        for (
            uint i = endorsementInfo[tokenId].length - (offset + 1);
            i > 0;
            i--
        ) {
            if (
                skipRevoked &&
                endorsementInfo[tokenId][i].status == EndorsementStatus(2)
            ) {
                continue;
            }
            endorsements[j] = endorsementInfo[tokenId][i];
            j++;
            if (j == 20) {
                break;
            }
        }
        return endorsements;
    }
}
