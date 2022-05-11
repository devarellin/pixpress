// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract PxaMarket is Ownable, Pausable {
  // constants
  uint256 public constant PXA_RATE_BASE = 1e6;

  struct PxaOrder {
    address seller;
    uint256 tokenId;
    uint256 price;
    uint256 revenue;
    uint256 index;
  }

  // events

  event OrderCreated(uint256 indexed tokenId, address seller, uint256 price);
  event Bought(uint256 indexed tokenId, uint256 price, uint256 revenue);
  event Claimed(uint256 indexed tokenId, uint256 revenue);
  event OrderRemoved(uint256 indexed tokenId, uint256 revenue);
  event RevenueIncreased(uint256 indexed tokenId, uint256 revenue);

  mapping(uint256 => PxaOrder) _orders;

  // vars

  uint256[] private _orderIds = new uint256[](0);
  address private _pxaAddress;
  uint256 private _pxaFeeRatio;

  constructor(address pxaAddress) {
    _pxaAddress = pxaAddress;
    _pxaFeeRatio = 5000;
  }

  function pxaOrder(uint256 tokenId) external view returns (PxaOrder memory order) {
    return _orders[tokenId];
  }

  function createOrder(uint256 tokenId, uint256 price) external whenNotPaused {
    require(IERC721(_pxaAddress).ownerOf(tokenId) == msg.sender, "PxaMarket: invalid token owner");
    IERC721(_pxaAddress).safeTransferFrom(msg.sender, address(this), tokenId);
    _orders[tokenId] = PxaOrder(msg.sender, tokenId, price, 0, _orderIds.length);
    _orderIds.push(tokenId);

    emit OrderCreated(tokenId, msg.sender, price);
  }

  function buy(uint256 tokenId) external payable whenNotPaused {
    require(msg.value >= _orders[tokenId].price, "PxaMarket: insufficient CELO");
    uint256 fee = (msg.value * _pxaFeeRatio) / PXA_RATE_BASE;
    uint256 rest = msg.value - fee;
    payable(owner()).transfer(fee);
    payable(_orders[tokenId].seller).transfer(rest);
    _claim(msg.sender, tokenId);
    IERC721(_pxaAddress).safeTransferFrom(address(this), msg.sender, tokenId);
    _remove(tokenId);

    emit Bought(tokenId, msg.value, _orders[tokenId].revenue);
  }

  function cancelOrder(uint256 tokenId) external payable whenNotPaused {
    require(msg.sender == _orders[tokenId].seller, "PxaMarket: invalid seller");
    uint256 revenue = _orders[tokenId].revenue;
    _claim(msg.sender, tokenId);
    _remove(tokenId);
    IERC721(_pxaAddress).safeTransferFrom(address(this), msg.sender, tokenId);

    emit OrderRemoved(tokenId, revenue);
  }

  function _remove(uint256 tokenId) internal {
    uint256 removeIndex = _orders[tokenId].index;
    uint256 replaceIndex = _orderIds.length - 1;
    _orderIds[removeIndex] = _orderIds[replaceIndex];
    _orders[_orderIds[replaceIndex]].index = removeIndex;
    delete _orders[tokenId];
    _orderIds.pop();
  }

  function _shareRevenue(uint256 totalRevenue) internal {
    if (_orderIds.length == 0) return;
    uint256 revenue = totalRevenue / _orderIds.length;
    for (uint256 i = 0; i < _orderIds.length; i++) {
      _orders[_orderIds[i]].revenue += revenue;
      emit RevenueIncreased(_orderIds[i], _orders[_orderIds[i]].revenue);
    }
  }

  function setTokenAddress(address pxaAddress) external onlyOwner {
    _pxaAddress = pxaAddress;
  }

  function setPxaFeeRatio(uint256 value) external onlyOwner {
    _pxaFeeRatio = value;
  }

  function pxaFeeRatio() external view returns (uint256) {
    return _pxaFeeRatio;
  }

  function claim(uint256 tokenId) external payable whenNotPaused {
    _claim(msg.sender, tokenId);
  }

  function _claim(address receiver, uint256 tokenId) internal {
    uint256 unclaimed = _orders[tokenId].revenue;
    if (unclaimed == 0) return;
    require(unclaimed <= address(this).balance, "PxaMarket: insufficient balance");
    payable(receiver).transfer(unclaimed);
    _orders[tokenId].revenue = 0;
    emit Claimed(tokenId, unclaimed);
  }
}
