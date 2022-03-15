// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import "./AssetSwapper.sol";
import "./PxaMarket.sol";
import "./PxtPool.sol";

contract Pixpress is AssetSwapper, PxaMarket, PxtPool {
  constructor(address pxaAddress, IERC20 pxtAddress) PxaMarket(pxaAddress) PxtPool(pxtAddress) {}

  // vars
  uint256 _pxaFeeShareRatio = 50000;

  function proposeSwap(
    address receiver,
    string calldata note,
    address[] calldata tokenAddresses,
    uint256[] calldata amounts,
    uint256[] calldata ids,
    uint8[] calldata protocols,
    bool[] calldata wanted
  ) external payable nonReentrant {
    require(tokenAddresses.length == amounts.length, "Pixpress: amount record size does not match");
    require(tokenAddresses.length == ids.length, "Pixpress: id record size does not match");
    require(tokenAddresses.length == protocols.length, "Pixpress: protocol record size does not match");
    require(tokenAddresses.length == wanted.length, "Pixpress: wanted record size does not match");
    uint256 fee = _calcSwapFee(tokenAddresses, amounts, wanted);
    require(msg.value >= fee, "Pixpress: insufficient swap fee");

    _proposeSwap(receiver, note, tokenAddresses, amounts, ids, protocols, wanted);
    uint256 feeShare = (fee * _pxaFeeShareRatio) / PXA_RATE_BASE;
    _shareRevenue(feeShare);
  }

  function proposeSwapWithPxt(
    address receiver,
    string calldata note,
    address[] calldata tokenAddresses,
    uint256[] calldata amounts,
    uint256[] calldata ids,
    uint8[] calldata protocols,
    bool[] calldata wanted
  ) external payable nonReentrant {
    uint256 fee = _perDeposit();
    _userDesposit(msg.sender, fee);
    _proposeSwap(receiver, note, tokenAddresses, amounts, ids, protocols, wanted);
  }

  function matchSwap(
    uint256 proposeId,
    address[] calldata tokenAddresses,
    uint256[] calldata amounts,
    uint256[] calldata ids,
    uint8[] calldata protocols,
    bool[] calldata wanted
  ) external payable nonReentrant {
    uint256 fee = _calcSwapFee(tokenAddresses, amounts, wanted);
    require(msg.value >= fee, "Pixpress: insufficient swap fee");

    _matchSwap(proposeId, tokenAddresses, amounts, ids, protocols);
    uint256 feeShare = (fee * _pxaFeeShareRatio) / PXA_RATE_BASE;
    _shareRevenue(feeShare);
  }

  function matchSwapWithPxt(
    uint256 proposeId,
    address[] calldata tokenAddresses,
    uint256[] calldata amounts,
    uint256[] calldata ids,
    uint8[] calldata protocols
  ) external payable nonReentrant {
    uint256 fee = _perDeposit();
    _userDesposit(msg.sender, fee);
    _matchSwap(proposeId, tokenAddresses, amounts, ids, protocols);
  }

  function acceptSwap(uint256 proposeId, uint256 matchId) external nonReentrant {
    _acceptSwap(proposeId, matchId);
    uint256 reward = _perWithdraw();
    _userWithdraw(msg.sender, reward / 2);
    _userWithdraw(matchRecords[matchId].matcher, reward / 2);
  }

  function _calcSwapFee(
    address[] calldata tokenAddreses,
    uint256[] calldata amounts,
    bool[] calldata wanted
  ) internal view returns (uint256) {
    uint256 totalFee = 0;
    for (uint256 i = 0; i < tokenAddreses.length; i++) {
      if (wanted[i] == false) {
        totalFee += _assetFee(tokenAddreses[i]) * amounts[i];
      }
    }
    return totalFee;
  }
}
