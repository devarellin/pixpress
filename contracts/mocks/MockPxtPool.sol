// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract MockPxtPool is AccessControl {
  using SafeERC20 for IERC20Metadata;

  // constants
  bytes32 public constant COORDINATOR = keccak256("COORDINATOR");

  // vars
  IERC20Metadata private _pxtAddress;
  uint256 public poolWindowRange;
  uint256 public poolUpperBoundary;
  uint256 public poolLowerBoundary;
  string public name = "Pixaton Pool I";

  constructor(IERC20Metadata pxtAddress) {
    _pxtAddress = pxtAddress;
    poolWindowRange = 10;
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(COORDINATOR, msg.sender);
  }

  function _balanceOf(address user) internal view returns (uint256) {
    return _pxtAddress.balanceOf(user);
  }

  function balance() public view returns (uint256) {
    return _pxtAddress.balanceOf(address(this));
  }

  function setWindowRange(uint256 value) external onlyRole(COORDINATOR) {
    poolWindowRange = value;
    _updateWindow(balance());
  }

  function systemDeposit(uint256 value) external onlyRole(COORDINATOR) {
    _pxtAddress.safeTransferFrom(msg.sender, address(this), value);
    _updateWindow(balance());
  }

  function systemWithdraw(uint256 value) external onlyRole(COORDINATOR) {
    _pxtAddress.approve(msg.sender, value);
    _pxtAddress.safeTransfer(msg.sender, value);
    _updateWindow(balance());
  }

  function _updateWindow(uint256 value) internal {
    poolUpperBoundary = value * poolWindowRange;
    poolLowerBoundary = value / poolWindowRange;
  }

  function perDeposit() public view returns (uint256) {
    if (balance() == 0) return (poolUpperBoundary / poolWindowRange) * 10**_pxtAddress.decimals();
    return poolUpperBoundary / balance();
  }

  function perWithdraw() public view returns (uint256) {
    if (balance() == 0) return 0;
    return (balance() / poolLowerBoundary) * 10**_pxtAddress.decimals();
  }

  function userDesposit(address user, uint256 value) external onlyRole(COORDINATOR) {
    require(value >= perDeposit(), "PXT Pool: insufficient amount");
    _pxtAddress.safeTransferFrom(user, address(this), value);
  }

  function userWithdraw(address user, uint256 value) external onlyRole(COORDINATOR) {
    require(value <= perWithdraw(), "PXT Pool: insufficient balance");
    _pxtAddress.approve(user, value);
    _pxtAddress.safeTransfer(user, value);
  }
}
