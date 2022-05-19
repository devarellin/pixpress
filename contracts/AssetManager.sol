// SPDX-License-Identifier: GPL-3.0

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/IAssetManager.sol";

pragma solidity ^0.8.12;

contract AssetManager is IAssetManager, AccessControl, ReentrancyGuard, Pausable {
  // constants
  uint256 public constant AM_RATE_BASE = 1e6;
  uint8 public constant PROTOCOL_ERC20 = 1;
  uint8 public constant PROTOCOL_ERC721 = 2;
  uint8 public constant PROTOCOL_ERC1155 = 3;
  bytes32 public constant COORDINATOR = keccak256("COORDINATOR");

  // vars
  uint256 _amFeeBase = 10 ether;
  uint256 _amFeeRatio = 10000;

  mapping(address => Asset) public assets;

  constructor() {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(COORDINATOR, msg.sender);
  }

  function asset(address tokenAddress) external view returns (Asset memory record) {
    return assets[tokenAddress];
  }

  function createAsset(
    address tokenAddress,
    uint8 protocol,
    uint256 base,
    uint256 ratio
  ) external onlyRole(COORDINATOR) {
    require(assets[tokenAddress].tokenAddress == address(0x0), "AssetManager: asset already exist");
    assets[tokenAddress] = Asset(tokenAddress, protocol, base, ratio);

    emit AssetCreated(tokenAddress, assets[tokenAddress]);
  }

  function removeAsset(address tokenAddress) external onlyRole(COORDINATOR) {
    delete assets[tokenAddress];

    emit AssetRemoved(tokenAddress);
  }

  function setAssetFeeBase(address tokenAddress, uint256 base) external onlyRole(COORDINATOR) {
    require(assets[tokenAddress].tokenAddress != address(0x0), "AssetManager: asset does not exist");
    assets[tokenAddress].feeBase = base;

    emit AssetFeeBaseUpdated(tokenAddress, base);
  }

  function setAssetFeeRatio(address tokenAddress, uint256 ratio) external onlyRole(COORDINATOR) {
    require(assets[tokenAddress].tokenAddress != address(0x0), "AssetManager: asset does not exist");
    assets[tokenAddress].feeRatio = ratio;

    emit AssetFeeRatioUpdated(tokenAddress, ratio);
  }

  function setAmFeeBase(uint256 value) external onlyRole(COORDINATOR) {
    _amFeeBase = value;

    emit DefaultAssetFeeBaseUpdated(value);
  }

  function amFeeBase() external view returns (uint256) {
    return _amFeeBase;
  }

  function setAmFeeRatio(uint256 value) external onlyRole(COORDINATOR) {
    _amFeeRatio = value;

    emit DefaultAssetFeeRatioUpdated(value);
  }

  function amFeeRatio() external view returns (uint256) {
    return _amFeeRatio;
  }

  function _assetFee(
    address tokenAddress,
    uint8 protocol,
    uint256 amount
  ) internal view returns (uint256) {
    if (assets[tokenAddress].tokenAddress == address(0x0)) {
      if (protocol == PROTOCOL_ERC20) {
        return (amount * _amFeeRatio) / AM_RATE_BASE;
      } else {
        return (_amFeeBase * _amFeeRatio) / AM_RATE_BASE;
      }
    } else {
      if (protocol == PROTOCOL_ERC20) {
        return (amount * assets[tokenAddress].feeRatio) / AM_RATE_BASE;
      } else {
        return (assets[tokenAddress].feeBase * assets[tokenAddress].feeRatio) / AM_RATE_BASE;
      }
    }
  }
}
