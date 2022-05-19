// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

interface IPxtPool {
  function name() external view returns (string memory);

  function balance() external view returns (uint256);

  function setWindowRange(uint256 value) external;

  function systemDeposit(uint256 value) external;

  function systemWithdraw(uint256 value) external;

  function perDeposit() external view returns (uint256);

  function perWithdraw() external view returns (uint256);

  function userDesposit(address user, uint256 value) external;

  function userWithdraw(address user, uint256 value) external;
}
