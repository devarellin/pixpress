// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract PxtPool is Ownable {
  using SafeERC20 for IERC20;
  // vars
  IERC20 private _pxtAddress;
  uint256 private _poolWindow;
  uint256 private _poolWindowUpperLimit;
  uint256 private _poolWindowLowerLimit;

  constructor(IERC20 pxtAddress) {
    _pxtAddress = pxtAddress;
    _poolWindow = 10;
  }

  function _balanceOf(address user) internal view returns (uint256) {
    return _pxtAddress.balanceOf(user);
  }

  function _balance() internal view returns (uint256) {
    return _pxtAddress.balanceOf(address(this));
  }

  function balance() external view returns (uint256) {
    return _balance();
  }

  function ownerDeposit(uint256 value) external onlyOwner {
    _pxtAddress.safeTransferFrom(msg.sender, address(this), value);
    uint256 newBalance = _balance() + value;
    _updateWindow(newBalance);
  }

  function ownerWithdraw(uint256 value) external onlyOwner {
    require(value > _balance(), "PXT Pool: insufficient balance");
    _pxtAddress.safeTransferFrom(address(this), msg.sender, value);
    uint256 newBalance = _balance() - value;
    _updateWindow(newBalance);
  }

  function _updateWindow(uint256 value) internal {
    _poolWindowUpperLimit = value * _poolWindow;
    _poolWindowLowerLimit = value / _poolWindow;
  }

  function _perDeposit() internal view returns (uint256) {
    return _poolWindowUpperLimit / _balance();
  }

  function _perWithdraw() internal view returns (uint256) {
    return _poolWindowLowerLimit / _balance();
  }

  function _userDesposit(address user, uint256 value) internal {
    require(value >= _perDeposit(), "PXT Pool: insufficient amount");
    _pxtAddress.safeTransferFrom(user, address(this), value);
  }

  function _userWithdraw(address user, uint256 value) internal {
    require(value <= _perWithdraw(), "PXT Pool: insufficient balance");
    _pxtAddress.safeTransferFrom(address(this), user, value);
  }
}
