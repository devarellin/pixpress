// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./interfaces/IPxaMarket.sol";
import "./interfaces/IPWS.sol";

contract MockPxaMarket is Pausable, IPxaMarket, AccessControl, ERC721Holder {
  // constants
  bytes32 public constant COORDINATOR = keccak256("COORDINATOR");
  uint256 public constant RATE_BASE = 1e6;

  mapping(uint256 => Order) _orders;

  // vars

  uint256 private _income;
  uint256[] private _orderIds = new uint256[](0);
  address private _pxaAddress;
  address private _pwsAddress;
  uint256 private _feeRatio;
  uint256 private _feeShareRatio;
  string public name = "PixelAva Market";

  constructor(address pxaAddr, address pxaWeightAddr) {
    _pxaAddress = pxaAddr;
    _pwsAddress = pxaWeightAddr;
    _feeRatio = 10000;
    _feeShareRatio = 500000;
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(COORDINATOR, msg.sender);
  }

  function order(uint256 tokenId) external view returns (Order memory _order) {
    return _orders[tokenId];
  }

  function createOrder(uint256 tokenId, uint256 price) external whenNotPaused {
    require(IERC721(_pxaAddress).ownerOf(tokenId) == msg.sender, "PxaMarket: invalid token owner");
    IERC721(_pxaAddress).safeTransferFrom(msg.sender, address(this), tokenId);
    _orders[tokenId] = Order(msg.sender, tokenId, price, 0, _orderIds.length);
    _orderIds.push(tokenId);

    emit OrderCreated(tokenId, msg.sender, price);
  }

  function buy(uint256 tokenId) external payable whenNotPaused {
    require(msg.value >= _orders[tokenId].price, "PxaMarket: insufficient CELO");
    uint256 fee = (msg.value * _feeRatio) / RATE_BASE;
    uint256 rest = msg.value - fee;
    uint256 feeShare = (fee * _feeShareRatio) / RATE_BASE;
    _donate(feeShare);
    uint256 feeForOwner = fee - feeShare;
    _addIncome(feeForOwner);
    payable(_orders[tokenId].seller).transfer(rest);
    _claim(msg.sender, tokenId);
    IERC721(_pxaAddress).safeTransferFrom(address(this), msg.sender, tokenId);
    _remove(tokenId);

    emit Bought(tokenId, msg.value, _orders[tokenId].revenue);
  }

  function claim(uint256 tokenId) external payable whenNotPaused {
    _claim(msg.sender, tokenId);
  }

  function cancelOrder(uint256 tokenId) external payable whenNotPaused {
    require(msg.sender == _orders[tokenId].seller, "PxaMarket: invalid seller");
    uint256 revenue = _orders[tokenId].revenue;
    _claim(msg.sender, tokenId);
    _remove(tokenId);
    IERC721(_pxaAddress).safeTransferFrom(address(this), msg.sender, tokenId);

    emit OrderRemoved(tokenId, revenue);
  }

  function pxaAddress() external view returns (address) {
    return _pxaAddress;
  }

  function setPxaAddress(address value) external onlyRole(COORDINATOR) {
    _pxaAddress = value;
  }

  function pwsAddress() external view returns (address) {
    return _pwsAddress;
  }

  function setPwsAddress(address value) external onlyRole(COORDINATOR) {
    _pwsAddress = value;
  }

  function rateBase() external pure returns (uint256) {
    return RATE_BASE;
  }

  function feeRatio() external view returns (uint256) {
    return _feeRatio;
  }

  function setFeeRatio(uint256 value) external onlyRole(COORDINATOR) {
    _feeRatio = value;
  }

  function feeShareRatio() external view returns (uint256) {
    return _feeShareRatio;
  }

  function setFeeShareRatio(uint256 value) external onlyRole(COORDINATOR) {
    _feeShareRatio = value;
  }

  function donate() public payable {
    _donate(msg.value);
  }

  function income() external view returns (uint256) {
    return _income;
  }

  function addIncome() external payable {
    _addIncome(msg.value);
  }

  function claimIncome(address receiver, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(_income >= amount && address(this).balance >= amount, "PxaMarket: insufficient income to claim");
    payable(receiver).transfer(amount);
    _income = _income - amount;
    emit IncomeClaimed(receiver, amount);
  }

  function withdraw(address receiver, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(address(this).balance >= amount, "PxaMarket: insufficient balance to withdraw");
    payable(receiver).transfer(amount);
    emit Withdraw(receiver, amount);
  }

  function _remove(uint256 tokenId) internal {
    uint256 removeIndex = _orders[tokenId].index;
    uint256 replaceIndex = _orderIds.length - 1;
    _orderIds[removeIndex] = _orderIds[replaceIndex];
    _orders[_orderIds[replaceIndex]].index = removeIndex;
    delete _orders[tokenId];
    _orderIds.pop();
  }

  function _donate(uint256 amount) internal {
    if (_orderIds.length == 0) return;
    uint256 totalWeight = IPWS(_pwsAddress).totalWeightOf(_orderIds);
    for (uint256 i = 0; i < _orderIds.length; i++) {
      uint256 id = _orderIds[i];
      uint256 weight = IPWS(_pwsAddress).weight(id);
      uint256 revenue = (amount * weight) / totalWeight;
      _orders[id].revenue += revenue;
      emit RevenueIncreased(id, _orders[id].revenue);
    }
  }

  function _claim(address receiver, uint256 tokenId) internal {
    uint256 unclaimed = _orders[tokenId].revenue;
    if (unclaimed == 0) return;
    require(unclaimed <= address(this).balance, "PxaMarket: insufficient balance");
    payable(receiver).transfer(unclaimed);
    _orders[tokenId].revenue = 0;
    emit Claimed(tokenId, unclaimed);
  }

  function _addIncome(uint256 amount) internal {
    _income = _income + amount;
    emit IncomeAdded(amount);
  }

  function pause() external onlyRole(COORDINATOR) {
    _pause();
  }

  function resume() external onlyRole(COORDINATOR) {
    _unpause();
  }
}
