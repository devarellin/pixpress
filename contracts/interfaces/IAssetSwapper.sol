// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import "./IAssetManager.sol";

interface IAssetSwapper {
  struct ProposeRecord {
    address proposer;
    address receiver;
    string note;
    address[] tokenAddresses;
    uint256[] amounts;
    uint256[] ids;
    uint8[] protocols;
    bool[] wanted;
    uint256[] matchRecordIds;
  }

  struct MatchRecord {
    uint256 proposeId;
    address matcher;
    address[] tokenAddresses;
    uint256[] amounts;
    uint256[] ids;
    uint8[] protocols;
    uint256 index;
  }

  // events
  event Proposed(uint256 indexed id, ProposeRecord record);
  event Matched(uint256 indexed id, MatchRecord record);
  event Swapped(uint256 indexed proposeId, uint256 indexed matchId);
  event ProposalRemoved(uint256 indexed id, ProposeRecord record);
  event MatcherRemoved(uint256 indexed id, MatchRecord record);

  function proposeRecord(uint256 id) external view returns (ProposeRecord memory record);

  function matchRecord(uint256 id) external view returns (MatchRecord memory record);

  function removeProposeRecord(uint256 proposeId) external;

  function removeMatchRecord(uint256 matchId) external;
}
