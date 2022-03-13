// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract PxaMarket is Ownable {
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

  event OrderCreated(uint256 indexed tokenId, uint256 price);
  event Bought(uint256 indexed tokenId, uint256 price, uint256 revenue);
  event Claimed(uint256 indexed tokenId, uint256 revenue);
  event OrderRemoved(uint256 indexed tokenId, uint256 revenue);
  event RevenueIncreased(uint256 indexed tokenId, uint256 revenue);

  mapping(uint256 => PxaOrder) public orders;

  // vars

  uint256[] private _orderIds = new uint256[](0);
  address private _pxaAddress;
  uint256 private _pxaFeeRatio;

  constructor(address pxaAddress) {
    _pxaAddress = pxaAddress;
    _pxaFeeRatio = 5000;
  }

  function createOrder(uint256 tokenId, uint256 price) external {
    require(IERC721(_pxaAddress).ownerOf(tokenId) == msg.sender, "PxaMarket: invalid token owner");
    IERC721(_pxaAddress).safeTransferFrom(msg.sender, address(this), tokenId);
    orders[tokenId] = PxaOrder(msg.sender, tokenId, price, 0, _orderIds.length);
    _orderIds.push(tokenId);

    emit OrderCreated(tokenId, price);
  }

  function buy(uint256 tokenId) external payable {
    require(msg.value >= orders[tokenId].price, "PxaMarket: insufficient CELO");

    IERC721(_pxaAddress).safeTransferFrom(address(this), msg.sender, tokenId);

    address seller = IERC721(_pxaAddress).ownerOf(tokenId);
    _afterBuy(msg.sender, seller, tokenId);

    emit Bought(tokenId, msg.value, orders[tokenId].revenue);
  }

  function cancelOrder(uint256 tokenId) external payable {
    require(msg.sender == orders[tokenId].seller, "PxaMarket: invalid seller");
    uint256 revenue = orders[tokenId].revenue;
    _claim(msg.sender, revenue);
    _remove(tokenId);

    emit OrderRemoved(tokenId, revenue);
  }

  function _remove(uint256 tokenId) internal {
    uint256 removeIndex = orders[tokenId].index;
    uint256 replaceIndex = _orderIds[_orderIds.length - 1];
    _orderIds[removeIndex] = _orderIds[replaceIndex];
    orders[_orderIds[replaceIndex]].index = removeIndex;
    delete orders[tokenId];
    _orderIds.pop();
  }

  function _shareRevenue(uint256 totalRevenue) internal {
    uint256 revenue = totalRevenue / _orderIds.length;
    for (uint256 i = 0; i < _orderIds.length; i++) {
      orders[_orderIds[i]].revenue += revenue;
      emit RevenueIncreased(_orderIds[i], revenue);
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

  function _claim(address receiver, uint256 tokenId) internal {
    uint256 unclaimed = orders[tokenId].revenue;
    require(unclaimed > 0 && unclaimed <= address(this).balance, "PxaMarket: insufficient balance");
    payable(receiver).transfer(unclaimed);
    orders[tokenId].revenue = 0;
  }

  function _afterBuy(
    address buyer,
    address seller,
    uint256 tokenId
  ) internal {
    _claim(buyer, tokenId);
    uint256 price = orders[tokenId].price;
    uint256 fee = (price * _pxaFeeRatio) / PXA_RATE_BASE;
    payable(seller).transfer(price - fee);
    _remove(tokenId);
  }
}
