// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import "./AssetSwapper.sol";
import "./interfaces/IPxaMarket.sol";
import "./interfaces/IPxtPool.sol";

contract Pixpress is AssetSwapper {
  IPxaMarket private _pxaMarket;
  IPxtPool private _pxtPool;

  constructor(address pxaMarketAddr, address pxtPoolAddr) {
    _pxaMarket = IPxaMarket(pxaMarketAddr);
    _pxtPool = IPxtPool(pxtPoolAddr);
  }

  function setPxaMarket(address _addr) external onlyRole(COORDINATOR) {
    _pxaMarket = IPxaMarket(_addr);
  }

  function setPxtPool(address _addr) external onlyRole(COORDINATOR) {
    _pxtPool = IPxtPool(_addr);
  }

  function _processFee(uint256 _fee) internal {
    _pxaMarket.shareIncome{ value: _fee }();
  }

  function proposeSwap(
    address receiver,
    string memory note,
    address[] memory tokenAddresses,
    uint256[] memory amounts,
    uint256[] memory ids,
    uint8[] memory protocols,
    bool[] memory wanted
  ) external payable nonReentrant whenNotPaused {
    uint256 fee = swapFee(tokenAddresses, protocols, amounts, wanted);
    require(msg.value >= fee, "Pixpress: insufficient swap fee");
    _proposeSwap(receiver, note, tokenAddresses, amounts, ids, protocols, wanted);
    _processFee(fee);
  }

  function _depositPxt(address user) internal {
    uint256 fee = _pxtPool.perDeposit();
    _pxtPool.userDesposit(user, fee);
  }

  function _withdrawPxt(address[2] memory users) internal {
    uint256 fee = _pxtPool.perWithdraw();
    if (fee > 0) {
      for (uint256 i = 0; i < users.length; i++) {
        _pxtPool.userWithdraw(users[i], fee / users.length);
      }
    }
  }

  function proposeSwapWithPxt(
    address receiver,
    string memory note,
    address[] memory tokenAddresses,
    uint256[] memory amounts,
    uint256[] memory ids,
    uint8[] memory protocols,
    bool[] memory wanted
  ) external nonReentrant whenNotPaused {
    _depositPxt(msg.sender);
    _proposeSwap(receiver, note, tokenAddresses, amounts, ids, protocols, wanted);
  }

  function matchSwap(
    uint256 proposeId,
    address[] memory tokenAddresses,
    uint256[] memory amounts,
    uint256[] memory ids,
    uint8[] memory protocols
  ) external payable nonReentrant whenNotPaused {
    bool[] memory wanted = new bool[](tokenAddresses.length);
    for (uint256 i = 0; i < wanted.length; i++) {
      wanted[i] = false;
    }
    uint256 fee = swapFee(tokenAddresses, protocols, amounts, wanted);
    require(msg.value >= fee, "Pixpress: insufficient swap fee");
    _matchSwap(proposeId, tokenAddresses, amounts, ids, protocols);
    _processFee(fee);
  }

  function matchSwapWithPxt(
    uint256 proposeId,
    address[] memory tokenAddresses,
    uint256[] memory amounts,
    uint256[] memory ids,
    uint8[] memory protocols
  ) external nonReentrant whenNotPaused {
    _depositPxt(msg.sender);
    _matchSwap(proposeId, tokenAddresses, amounts, ids, protocols);
  }

  function acceptSwap(uint256 proposeId, uint256 matchId) external nonReentrant {
    _acceptSwap(proposeId, matchId);
    _withdrawPxt([msg.sender, _matchRecords[matchId].matcher]);
    _removeProposeRecord((proposeId));
  }

  function swapFee(
    address[] memory tokenAddreses,
    uint8[] memory protocols,
    uint256[] memory amounts,
    bool[] memory wanted
  ) public view returns (uint256) {
    uint256 totalFee = 0;
    for (uint256 i = 0; i < tokenAddreses.length; i++) {
      if (wanted[i] == false) {
        totalFee += _assetFee(tokenAddreses[i], protocols[i], amounts[i]);
      }
    }
    return totalFee;
  }

  function pause() external onlyRole(COORDINATOR) {
    _pause();
  }

  function resume() external onlyRole(COORDINATOR) {
    _unpause();
  }
}
