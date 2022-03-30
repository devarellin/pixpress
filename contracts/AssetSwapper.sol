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
  mapping(uint256 => ProposeRecord) _proposeRecords;
  Counters.Counter private _matchRecordIds;
  mapping(uint256 => MatchRecord) _matchRecords;

  function proposeRecord(uint256 id) external view returns (ProposeRecord memory record) {
    return _proposeRecords[id];
  }

  function matchRecord(uint256 id) external view returns (MatchRecord memory record) {
    return _matchRecords[id];
  }

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
    _proposeRecords[id] = ProposeRecord(
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

    emit Proposed(id, _proposeRecords[id]);
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
    _matchRecords[id] = MatchRecord(
      proposeId,
      msg.sender,
      tokenAddresses,
      amounts,
      ids,
      protocols,
      _proposeRecords[proposeId].matchRecordIds.length
    );
    _proposeRecords[proposeId].matchRecordIds.push(id);

    emit Matched(id, _matchRecords[id]);
  }

  function _acceptSwap(uint256 proposeId, uint256 matchId) internal {
    ProposeRecord storage pRecord = _proposeRecords[proposeId];
    MatchRecord storage mRecord = _matchRecords[matchId];
    require(pRecord.proposer == msg.sender, "Asset Swapper: invalid proposer");
    require(proposeId == mRecord.proposeId, "Asset Swapper: invalid match id");
    require(_proposeAssetsValid(pRecord), "Asset Swapper: proposer assets invalid");
    require(_matchAssetsValid(mRecord), "Asset Swapper: matcher assets invalid");

    for (uint256 index = 0; index < pRecord.tokenAddresses.length; index++) {
      if (pRecord.wanted[index] == true) continue;
      _transferAsset(
        pRecord.proposer,
        mRecord.matcher,
        pRecord.tokenAddresses[index],
        pRecord.amounts[index],
        pRecord.ids[index],
        pRecord.protocols[index]
      );
    }
    for (uint256 index = 0; index < mRecord.tokenAddresses.length; index++) {
      _transferAsset(
        mRecord.matcher,
        pRecord.proposer,
        mRecord.tokenAddresses[index],
        mRecord.amounts[index],
        mRecord.ids[index],
        mRecord.protocols[index]
      );
    }

    emit Swapped(proposeId, matchId);
  }

  function _proposeAssetsValid(ProposeRecord storage record) internal view returns (bool) {
    address proposer = record.proposer;
    address[] storage tokenAddresses = record.tokenAddresses;
    uint256[] storage tokenIds = record.ids;
    uint8[] storage protocols = record.protocols;
    uint256[] storage amounts = record.amounts;
    bool[] storage wanted = record.wanted;
    for (uint256 i = 0; i < tokenAddresses.length; i++) {
      if (wanted[i]) continue;
      require(
        _assetApproved(proposer, tokenAddresses[i], tokenIds[i], protocols[i], amounts[i]),
        "Asset Swapper: some proposer assets are not approved"
      );
      require(
        _assetInStock(proposer, tokenAddresses[i], tokenIds[i], protocols[i], amounts[i]),
        "Asset Swapper: some proposer assets are not in stock"
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
        "Asset Swapper: some matcher assets are not in stock"
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
      require(t.balanceOf(tokenOwner) >= amount, "Asset Swapper: ERC20 insufficient token balance");
    } else if (protocol == PROTOCOL_ERC721) {
      IERC721 t = IERC721(tokenAddress);
      require(t.ownerOf(tokenId) == tokenOwner, "Asset Swapper: ERC721 insufficient token balance");
    } else if (protocol == PROTOCOL_ERC1155) {
      IERC1155 t = IERC1155(tokenAddress);
      require(t.balanceOf(tokenOwner, tokenId) >= amount, "Asset Swapper: ERC1155 insufficient token balance");
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
    require((msg.sender == _proposeRecords[proposeId].proposer), "Asset Swapper: invalid proposer");
    _removeProposeRecord(proposeId);

    emit ProposalRemoved(proposeId, _proposeRecords[proposeId]);
  }

  function _removeProposeRecord(uint256 proposeId) internal {
    ProposeRecord storage record = _proposeRecords[proposeId];

    delete _proposeRecords[proposeId];
    for (uint256 index = 0; index < record.matchRecordIds.length; index++) {
      _removeMatchRecord(record.matchRecordIds[index]);
    }
  }

  function removeMatchRecord(uint256 matchId) public nonReentrant {
    require(_matchRecords[matchId].matcher == msg.sender, "Asset Swapper: invalid matcher");
    MatchRecord storage mRecord = _matchRecords[matchId];
    _removeProposeRecordMatchId(mRecord);
    _removeMatchRecord(matchId);

    emit MatcherRemoved(matchId, _matchRecords[matchId]);
  }

  function _removeProposeRecordMatchId(MatchRecord storage mRecord) internal {
    ProposeRecord storage pRecord = _proposeRecords[mRecord.proposeId];
    uint256 lastMatchIdIndex = pRecord.matchRecordIds.length - 1;
    MatchRecord storage lastMatchIdRecord = _matchRecords[pRecord.matchRecordIds[lastMatchIdIndex]];
    lastMatchIdRecord.index = mRecord.index;
    pRecord.matchRecordIds[mRecord.index] = pRecord.matchRecordIds[lastMatchIdIndex];
    pRecord.matchRecordIds.pop();
  }

  function _removeMatchRecord(uint256 matchId) internal {
    delete _matchRecords[matchId];
  }
}
