// SPDX-License-Identifier: GPL-3.0

import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity ^0.8.12;

contract AssetManager is Ownable {
  // constants
  uint256 public constant AM_RATE_BASE = 1e6;
  uint8 public constant PROTOCOL_ERC20 = 1;
  uint8 public constant PROTOCOL_ERC721 = 2;
  uint8 public constant PROTOCOL_ERC1155 = 3;

  struct Asset {
    address tokenAddress;
    uint8 protocol;
    uint256 feeBase;
    uint256 feeRatio;
  }

  // vars
  uint256 _amFeeBase = 10 ether;
  uint256 _amFeeRatio = 10000;

  // events
  event AssetCreated(address indexed tokenAddress, Asset record);
  event AssetRemoved(address indexed tokenAddress);
  event AssetFeeBaseUpdated(address indexed tokenAddress, uint256 feeBase);
  event AssetFeeRatioUpdated(address indexed tokenAddress, uint256 feeRatio);
  event DefaultAssetFeeBaseUpdated(uint256 feeBase);
  event DefaultAssetFeeRatioUpdated(uint256 feeRatio);

  mapping(address => Asset) public assets;

  function asset(address tokenAddress) external view returns (Asset memory record) {
    return assets[tokenAddress];
  }

  function createAsset(
    address tokenAddress,
    uint8 protocol,
    uint256 base,
    uint256 ratio
  ) external {
    require(assets[tokenAddress].tokenAddress == address(0x0), "AssetManager: asset already exist");
    assets[tokenAddress] = Asset(tokenAddress, protocol, base, ratio);

    emit AssetCreated(tokenAddress, assets[tokenAddress]);
  }

  function removeAsset(address tokenAddress) external onlyOwner {
    delete assets[tokenAddress];

    emit AssetRemoved(tokenAddress);
  }

  function setAssetFeeBase(address tokenAddress, uint256 base) external onlyOwner {
    require(assets[tokenAddress].tokenAddress != address(0x0), "AssetManager: asset does not exist");
    assets[tokenAddress].feeBase = base;

    emit AssetFeeBaseUpdated(tokenAddress, base);
  }

  function setAssetFeeRatio(address tokenAddress, uint256 ratio) external onlyOwner {
    require(assets[tokenAddress].tokenAddress != address(0x0), "AssetManager: asset does not exist");
    assets[tokenAddress].feeRatio = ratio;

    emit AssetFeeRatioUpdated(tokenAddress, ratio);
  }

  function setAmFeeBase(uint256 value) external onlyOwner {
    _amFeeBase = value;

    emit DefaultAssetFeeBaseUpdated(value);
  }

  function amFeeBase() external view returns (uint256) {
    return _amFeeBase;
  }

  function setAmFeeRatio(uint256 value) external onlyOwner {
    _amFeeRatio = value;

    emit DefaultAssetFeeRatioUpdated(value);
  }

  function amFeeRatio() external view returns (uint256) {
    return _amFeeRatio;
  }

  function _assetFee(address tokenAddress) internal view returns (uint256) {
    if (assets[tokenAddress].tokenAddress == address(0x0)) {
      return (_amFeeBase * _amFeeRatio) / AM_RATE_BASE;
    } else {
      return (assets[tokenAddress].feeBase * assets[tokenAddress].feeRatio) / AM_RATE_BASE;
    }
  }
}
