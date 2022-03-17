// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./AssetManager.sol";

contract AssetSwapper is AssetManager, ReentrancyGuard {
  using Counters for Counters.Counter;
  using SafeERC20 for IERC20;

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

  Counters.Counter private _proposeRecordIds;
  mapping(uint256 => ProposeRecord) proposeRecords;
  Counters.Counter private _matchRecordIds;
  mapping(uint256 => MatchRecord) matchRecords;

  function _proposeSwap(
    address receiver,
    string memory note,
    address[] memory tokenAddresses,
    uint256[] memory amounts,
    uint256[] memory ids,
    uint8[] memory protocols,
    bool[] memory wanted
  ) internal {
    require(tokenAddresses.length == amounts.length, "Asset Swapper: amount record size does not match");
    require(tokenAddresses.length == ids.length, "Asset Swapper: id record size does not match");
    require(tokenAddresses.length == protocols.length, "Asset Swapper: protocol record size does not match");
    require(tokenAddresses.length == wanted.length, "Asset Swapper: wanted record size does not match");

    _proposeRecordIds.increment();
    uint256 id = _proposeRecordIds.current();
    proposeRecords[id] = ProposeRecord(
      msg.sender,
      receiver,
      note,
      tokenAddresses,
      amounts,
      ids,
      protocols,
      wanted,
      new uint256[](0)
    );

    emit Proposed(id, proposeRecords[id]);
  }

  function _matchSwap(
    uint256 proposeId,
    address[] memory tokenAddresses,
    uint256[] memory amounts,
    uint256[] memory ids,
    uint8[] memory protocols
  ) internal {
    require(tokenAddresses.length == amounts.length, "Assest Swapper: amount record size does not match");
    require(tokenAddresses.length == ids.length, "Assest Swapper: id record size does not match");
    require(tokenAddresses.length == protocols.length, "Assest Swapper: protocol record size does not match");
    _matchRecordIds.increment();
    uint256 id = _matchRecordIds.current();
    matchRecords[id] = MatchRecord(
      proposeId,
      msg.sender,
      tokenAddresses,
      amounts,
      ids,
      protocols,
      proposeRecords[proposeId].matchRecordIds.length
    );
    proposeRecords[proposeId].matchRecordIds.push(id);

    emit Matched(id, matchRecords[id]);
  }

  function _acceptSwap(uint256 proposeId, uint256 matchId) internal {
    ProposeRecord storage proposeRecord = proposeRecords[proposeId];
    MatchRecord storage matchRecord = matchRecords[matchId];
    require(proposeRecord.proposer == msg.sender, "Asset Swapper: invalid proposer");
    require(proposeId == matchRecord.proposeId, "Asset Swapper: invalid match id");
    require(_proposeAssetsValid(proposeRecord), "Asset Swapper: proposer assets invalid");
    require(_matchAssetsValid(matchRecord), "Asset Swapper: matcher assets invalid");

    for (uint256 index = 0; index < proposeRecord.tokenAddresses.length; index++) {
      _transferAsset(
        proposeRecord.proposer,
        matchRecord.matcher,
        proposeRecord.tokenAddresses[index],
        proposeRecord.amounts[index],
        proposeRecord.ids[index],
        proposeRecord.protocols[index]
      );
    }
    for (uint256 index = 0; index < matchRecord.tokenAddresses.length; index++) {
      _transferAsset(
        matchRecord.matcher,
        proposeRecord.proposer,
        matchRecord.tokenAddresses[index],
        matchRecord.amounts[index],
        matchRecord.ids[index],
        matchRecord.protocols[index]
      );
    }

    delete proposeRecords[proposeId];
    for (uint256 index = 0; index < proposeRecord.matchRecordIds.length; index++) {
      delete matchRecords[proposeRecord.matchRecordIds[index]];
    }

    emit Swapped(proposeId, matchId);
  }

  function _proposeAssetsValid(ProposeRecord storage record) internal view returns (bool) {
    address proposer = record.proposer;
    address[] storage tokenAddresses = record.tokenAddresses;
    uint256[] storage tokenIds = record.ids;
    uint8[] storage protocols = record.protocols;
    uint256[] storage amounts = record.amounts;
    for (uint256 i = 0; i < tokenAddresses.length; i++) {
      require(
        _assetApproved(proposer, tokenAddresses[i], tokenIds[i], protocols[i], amounts[i]),
        "Asset Swapper: some proposer assets are not approved"
      );
      require(
        _assetInStock(proposer, tokenAddresses[i], tokenIds[i], protocols[i], amounts[i]),
        "Asset Swapper: some proposer assets are not approved"
      );
    }
    return true;
  }

  function _matchAssetsValid(MatchRecord storage record) internal view returns (bool) {
    address matcher = record.matcher;
    address[] storage tokenAddresses = record.tokenAddresses;
    uint256[] storage tokenIds = record.ids;
    uint8[] storage protocols = record.protocols;
    uint256[] storage amounts = record.amounts;
    for (uint256 i = 0; i < tokenAddresses.length; i++) {
      require(
        _assetApproved(matcher, tokenAddresses[i], tokenIds[i], protocols[i], amounts[i]),
        "Asset Swapper: some matcher assets are not approved"
      );
      require(
        _assetInStock(matcher, tokenAddresses[i], tokenIds[i], protocols[i], amounts[i]),
        "Asset Swapper: some matcher assets are not approved"
      );
    }
    return true;
  }

  function _assetApproved(
    address tokenOwner,
    address tokenAddress,
    uint256 tokenId,
    uint8 protocol,
    uint256 amount
  ) internal view returns (bool) {
    if (protocol == PROTOCOL_ERC20) {
      IERC20 t = IERC20(tokenAddress);
      require(t.allowance(tokenOwner, address(this)) >= amount, "Asset Swapper: insufficient token allowance");
    } else if (protocol == PROTOCOL_ERC721) {
      IERC721 t = IERC721(tokenAddress);
      require(
        t.getApproved(tokenId) == address(this) || t.isApprovedForAll(tokenOwner, address(this)),
        "Asset Swapper: ERC721 token not approved "
      );
    } else if (protocol == PROTOCOL_ERC1155) {
      IERC1155 t = IERC1155(tokenAddress);
      require(t.isApprovedForAll(tokenOwner, address(this)), "Asset Swapper: ERC1155 token not approved ");
    } else {
      revert("Asset Swapper: unsupported token protocol");
    }
    return true;
  }

  function _assetInStock(
    address tokenOwner,
    address tokenAddress,
    uint256 tokenId,
    uint8 protocol,
    uint256 amount
  ) internal view returns (bool) {
    if (protocol == PROTOCOL_ERC20) {
      IERC20 t = IERC20(tokenAddress);
      require(t.balanceOf(tokenOwner) >= amount, "Asset Swapper: insufficient token balance");
    } else if (protocol == PROTOCOL_ERC1155) {
      IERC1155 t = IERC1155(tokenAddress);
      require(t.balanceOf(tokenOwner, tokenId) >= amount, "Asset Swapper: insufficient token balance");
    } else {
      revert("Asset Swapper: unsupported token protocol");
    }
    return true;
  }

  function _transferAsset(
    address sender,
    address receiver,
    address tokenAddress,
    uint256 amount,
    uint256 id,
    uint8 protocol
  ) internal {
    // Normal ERC-20 transfer
    if (protocol == PROTOCOL_ERC20) {
      IERC20(tokenAddress).safeTransferFrom(sender, receiver, amount);
    } else if (protocol == PROTOCOL_ERC721) {
      IERC721(tokenAddress).safeTransferFrom(sender, receiver, id);
    } else if (protocol == PROTOCOL_ERC1155) {
      IERC1155(tokenAddress).safeTransferFrom(sender, receiver, id, amount, "");
    } else {
      revert("Asset Swapper: cannot swap unsupported token protocol");
    }
  }

  function removeProposeRecord(uint256 proposeId) external nonReentrant {
    require((msg.sender == proposeRecords[proposeId].proposer), "Asset Swapper: invalid proposer");
    _removeProposeRecord(proposeId);

    emit ProposalRemoved(proposeId, proposeRecords[proposeId]);
  }

  function _removeProposeRecord(uint256 proposeId) internal {
    ProposeRecord storage record = proposeRecords[proposeId];

    delete proposeRecords[proposeId];
    for (uint256 index = 0; index < record.matchRecordIds.length; index++) {
      _removeMatchRecord(record.matchRecordIds[index]);
    }
  }

  function removeMatchRecord(uint256 matchId) public nonReentrant {
    require(matchRecords[matchId].matcher == msg.sender, "Asset Swapper: invalid matcher");
    MatchRecord storage matchRecord = matchRecords[matchId];
    _removeProposeRecordMatchId(matchRecord);
    _removeMatchRecord(matchId);

    emit MatcherRemoved(matchId, matchRecords[matchId]);
  }

  function _removeProposeRecordMatchId(MatchRecord storage matchRecord) internal {
    ProposeRecord storage proposeRecord = proposeRecords[matchRecord.proposeId];
    uint256 lastMatchIdIndex = proposeRecord.matchRecordIds.length - 1;
    MatchRecord storage lastMatchIdRecord = matchRecords[proposeRecord.matchRecordIds[lastMatchIdIndex]];
    lastMatchIdRecord.index = matchRecord.index;
    proposeRecord.matchRecordIds[matchRecord.index] = proposeRecord.matchRecordIds[lastMatchIdIndex];
    proposeRecord.matchRecordIds.pop();
  }

  function _removeMatchRecord(uint256 matchId) internal {
    delete matchRecords[matchId];
  }
}
