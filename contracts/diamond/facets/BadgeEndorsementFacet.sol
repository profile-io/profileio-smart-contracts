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
    /// @dev User interacts with the Diamond contract directly when doing endorsement actions.
    function endorse(
        address _badge,
        uint256 _tokenId
    ) external returns (uint256 total) {
        badgeCheck(_badge, _tokenId);

        EndorsementInfo memory endorsement = checkEndorsementInfo(
            msg.sender,
            address(_badge),
            _tokenId
        );

        if (endorsement.status == EndorsementStatus(0)) {
            return _endorse(address(_badge), _tokenId);
        } else if (endorsement.status == EndorsementStatus(2)) {
            return _endorseUpdate(address(_badge), _tokenId);
        } else {
            revert("BadgeEndorsementFacet: Already endorsed");
        }
    }

    /// @dev NotSet => Endorsed.
    function _endorse(
        address _badge,
        uint256 _tokenId
    ) internal returns (uint256 total) {
        EndorsementInfo memory endorsement = EndorsementInfo({
            timestamp: block.timestamp,
            sender: msg.sender,
            status: EndorsementStatus(1)
        });

        uint k = uint(uint160(_badge)) + _tokenId;

        s.endorsementInfoIndex[msg.sender][k] = s
        .endorsementInfo[_badge][_tokenId].length;
        s.endorsementInfo[_badge][_tokenId].push(endorsement);

        emit LibEndorsement.Endorsed(msg.sender, _badge, _tokenId);
        return
            s.endorsementInfo[_badge][_tokenId].length -
            s.revoked[_badge][_tokenId];
    }

    /// @dev Revoked => Endorsed.
    function _endorseUpdate(
        address _badge,
        uint256 _tokenId
    ) internal returns (uint256 total) {
        uint k = uint(uint160(_badge)) + _tokenId;

        uint i = s.endorsementInfoIndex[msg.sender][k];

        s.endorsementInfo[_badge][_tokenId][i].timestamp = block.timestamp;
        s.endorsementInfo[_badge][_tokenId][i].status = EndorsementStatus(1);

        s.revoked[_badge][_tokenId] -= 1;

        emit LibEndorsement.Endorsed(msg.sender, _badge, _tokenId);
        return
            s.endorsementInfo[_badge][_tokenId].length -
            s.revoked[_badge][_tokenId];
    }

    /// @return total The new total number of endorsements for the provided tokenId.
    function revokeEndorsement(
        address _badge,
        uint256 _tokenId
    ) external returns (uint256 total) {
        badgeCheck(_badge, _tokenId);

        uint k = uint(uint160(_badge)) + _tokenId;
        uint i = s.endorsementInfoIndex[msg.sender][k];

        require(
            s.endorsementInfo[_badge][_tokenId][i].sender == msg.sender,
            "Badge: Sender mismatch"
        );
        require(
            s.endorsementInfo[_badge][_tokenId][i].status ==
                EndorsementStatus(1),
            "Badge: Not endorsed"
        );

        s.endorsementInfo[_badge][_tokenId][i].timestamp = block.timestamp;
        s.endorsementInfo[_badge][_tokenId][i].status = EndorsementStatus(2);
        s.revoked[_badge][_tokenId] += 1;
        emit LibEndorsement.Revoked(msg.sender, _badge, _tokenId);
        return
            s.endorsementInfo[_badge][_tokenId].length -
            s.revoked[_badge][_tokenId];
    }

    /// @notice Returns the endorsement info for a given tokenId.
    function checkEndorsementInfo(
        address _sender,
        address _badge,
        uint256 _tokenId
    ) public view returns (EndorsementInfo memory endorsement) {
        /// @dev Get k in (k,v) mapping by concatenating the address and tokenId.
        uint k = uint(uint160(_badge)) + _tokenId;
        uint i = s.endorsementInfoIndex[_sender][k];

        /// @dev Index 0 will always be the tokenId owner.
        if (i == 0) {
            return endorsement;
        }
        return s.endorsementInfo[_badge][_tokenId][i];
    }

    /// @notice Returns the actual number of endorsements for a given tokenId.
    function getEndorsementsTotal(
        address _badge,
        uint256 _tokenId
    ) external view returns (uint256) {
        if (
            s.endorsementInfo[_badge][_tokenId].length ==
            s.revoked[_badge][_tokenId]
        ) {
            return 0;
        }
        return
            s.endorsementInfo[_badge][_tokenId].length -
            (1 + s.revoked[_badge][_tokenId]);
    }

    /// @notice Includes revoked endorsements.
    function getEndorsementInfoTotal(
        address _badge,
        uint256 _tokenId
    ) external view returns (uint256) {
        if (s.endorsementInfo[_badge][_tokenId].length == 0) {
            return 0;
        }
        return s.endorsementInfo[_badge][_tokenId].length - 1;
    }

    function getEndorsements(
        address _badge,
        uint256 _tokenId
    ) external view returns (EndorsementInfo[] memory) {
        return s.endorsementInfo[_badge][_tokenId];
    }

    function get20Endorsements(
        address _badge,
        uint256 _tokenId,
        uint256 _offset,
        bool _skipRevoked
    ) external view returns (EndorsementInfo[20] memory endorsements) {
        uint j;
        if (s.endorsementInfo[_badge][_tokenId].length - 1 < _offset) {
            return endorsements;
        }
        for (
            uint i = s.endorsementInfo[_badge][_tokenId].length - (_offset + 1);
            i > 0;
            i--
        ) {
            if (
                _skipRevoked &&
                s.endorsementInfo[_badge][_tokenId][i].status ==
                EndorsementStatus(2)
            ) {
                continue;
            }
            endorsements[j] = s.endorsementInfo[_badge][_tokenId][i];
            j++;
            if (j == 20) {
                break;
            }
        }
        return endorsements;
    }

    function badgeCheck(
        address _badge,
        uint256 _tokenId
    ) public view returns (bool) {
        require(
            s.badgeParams[_badge].endorsementEnabled == 1,
            "Badge: Endorsement disabled"
        );
        require(
            IERC721(_badge).ownerOf(_tokenId) != msg.sender,
            "Badge: Cannot endorse own badge"
        );
        require(
            IERC721(_badge).ownerOf(_tokenId) != address(0),
            "Badge: Invalid tokenId"
        );
        return true;
    }
}
