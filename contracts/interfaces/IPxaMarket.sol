// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

interface IPxaMarket {
  struct Order {
    address seller;
    uint256 tokenId;
    uint256 price;
    uint256 revenue;
    uint256 index;
  }

  event OrderCreated(uint256 indexed tokenId, address seller, uint256 price);
  event Bought(uint256 indexed tokenId, uint256 price, uint256 revenue);
  event Claimed(uint256 indexed tokenId, uint256 revenue);
  event OrderRemoved(uint256 indexed tokenId, uint256 revenue);
  event RevenueIncreased(uint256 indexed tokenId, uint256 revenue);
  event IncomeAdded(uint256 amount);
  event IncomeClaimed(address indexed receiver, uint256 amount);
  event Withdraw(address indexed receiver, uint256 amount);

  function rateBase() external view returns (uint256);

  function name() external view returns (string memory);

  function order(uint256 tokenId) external view returns (Order memory order);

  function createOrder(uint256 tokenId, uint256 price) external;

  function buy(uint256 tokenId) external payable;

  function claim(uint256 tokenId) external payable;

  function cancelOrder(uint256 tokenId) external payable;

  function pxaAddress() external view returns (address);

  function setPxaAddress(address value) external;

  function pwsAddress() external view returns (address);

  function setPwsAddress(address value) external;

  function feeRatio() external view returns (uint256);

  function setFeeRatio(uint256 value) external;

  function feeShareRatio() external view returns (uint256);

  function setFeeShareRatio(uint256 value) external;

  function addDividend() external payable;

  function shareIncome() external payable;

  function income() external view returns (uint256);

  function addIncome() external payable;

  function claimIncome(address receiver, uint256 amount) external;

  function withdraw(address receiver, uint256 amount) external;
}
