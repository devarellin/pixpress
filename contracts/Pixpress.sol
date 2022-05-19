// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import "./AssetSwapper.sol";
import "./PxtPool.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./interfaces/IPxaMarket.sol";

contract Pixpress is AssetSwapper, PxtPool, ERC721Holder, ERC1155Holder {
  address public pxaMarketAddress;

  constructor(IERC20Metadata pxtAddress, address pxaMarketAddr) PxtPool(pxtAddress) {
    pxaMarketAddress = pxaMarketAddr;
  }

  function setPxaMarketAddress(address _addr) external {
    pxaMarketAddress = _addr;
  }

  function _processFee(uint256 _fee) internal {
    uint256 feeRatio = IPxaMarket(pxaMarketAddress).feeRatio();
    uint256 base = IPxaMarket(pxaMarketAddress).rateBase();
    uint256 feeShare = (_fee * feeRatio) / base;
    IPxaMarket(pxaMarketAddress).donate{ value: feeShare }();
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
    uint256 fee = calcSwapFee(tokenAddresses, protocols, amounts, wanted);
    require(msg.value >= fee, "Pixpress: insufficient swap fee");
    _proposeSwap(receiver, note, tokenAddresses, amounts, ids, protocols, wanted);
    _processFee(fee);
  }

  function proposeSwapWithPxt(
    address receiver,
    string memory note,
    address[] memory tokenAddresses,
    uint256[] memory amounts,
    uint256[] memory ids,
    uint8[] memory protocols,
    bool[] memory wanted
  ) external payable nonReentrant whenNotPaused {
    uint256 fee = perDeposit();
    _userDesposit(msg.sender, fee);
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
    uint256 fee = calcSwapFee(tokenAddresses, protocols, amounts, wanted);
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
  ) external payable nonReentrant whenNotPaused {
    uint256 fee = perDeposit();
    _userDesposit(msg.sender, fee);
    _matchSwap(proposeId, tokenAddresses, amounts, ids, protocols);
  }

  function acceptSwap(uint256 proposeId, uint256 matchId) external nonReentrant {
    _acceptSwap(proposeId, matchId);
    uint256 reward = perWithdraw();
    if (reward > 0) {
      _userWithdraw(msg.sender, reward / 2);
      _userWithdraw(_matchRecords[matchId].matcher, reward / 2);
    }
    _removeProposeRecord((proposeId));
  }

  function calcSwapFee(
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

  function pause() external onlyOwner {
    _pause();
  }

  function resume() external onlyOwner {
    _unpause();
  }
}
