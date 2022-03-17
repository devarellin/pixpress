// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "hardhat/console.sol";

contract PxtPool is Ownable {
  using SafeERC20 for IERC20;
  // vars
  IERC20 private _pxtAddress;
  uint256 public poolWindow;
  uint256 public poolUpperBoundary;
  uint256 public poolLowerBoundary;

  constructor(IERC20 pxtAddress) {
    _pxtAddress = pxtAddress;
    poolWindow = 10;
  }

  function _balanceOf(address user) internal view returns (uint256) {
    return _pxtAddress.balanceOf(user);
  }

  function balance() public view returns (uint256) {
    return _pxtAddress.balanceOf(address(this));
  }

  function ownerDeposit(uint256 value) external onlyOwner {
    _pxtAddress.safeTransferFrom(msg.sender, address(this), value);
    _updateWindow(balance());
  }

  function ownerWithdraw(uint256 value) external onlyOwner {
    _pxtAddress.approve(msg.sender, value);
    _pxtAddress.safeTransfer(msg.sender, value);
    _updateWindow(balance());
  }

  function _updateWindow(uint256 value) internal {
    poolUpperBoundary = value * poolWindow;
    poolLowerBoundary = value / poolWindow;
  }

  function perDeposit() public view returns (uint256) {
    return poolUpperBoundary / balance();
  }

  function perWithdraw() public view returns (uint256) {
    return poolLowerBoundary / balance();
  }

  function _userDesposit(address user, uint256 value) internal {
    require(value >= perDeposit(), "PXT Pool: insufficient amount");
    _pxtAddress.safeTransferFrom(user, address(this), value);
  }

  function _userWithdraw(address user, uint256 value) internal {
    require(value <= perWithdraw(), "PXT Pool: insufficient balance");
    _pxtAddress.safeTransferFrom(address(this), user, value);
  }
}
