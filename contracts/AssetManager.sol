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
    bool verified;
    uint256 feeBase;
    uint256 feeRatio;
  }

  // vars
  uint256 _amFeeBase = 10 ether;
  uint256 _amFeeRatio = 10000;

  mapping(address => Asset) public assets;

  function createAsset(address tokenAddress, uint8 protocol) external {
    require(assets[tokenAddress].tokenAddress == address(0x0), "AssetManager: asset already exist");
    assets[tokenAddress] = Asset(tokenAddress, protocol, false, _amFeeBase, _amFeeRatio);
  }

  function setAssetFeeBase(address tokenAddress, uint256 base) external onlyOwner {
    require(assets[tokenAddress].tokenAddress != address(0x0), "AssetManager: asset does not exist");
    assets[tokenAddress].feeBase = base;
  }

  function setAssetFeeRatio(address tokenAddress, uint256 ratio) external onlyOwner {
    require(assets[tokenAddress].tokenAddress != address(0x0), "AssetManager: asset does not exist");
    assets[tokenAddress].feeRatio = ratio;
  }

  function setAssetVerified(address tokenAddress, bool verified) external onlyOwner {
    require(assets[tokenAddress].tokenAddress != address(0x0), "AssetManager: asset does not exist");
    assets[tokenAddress].verified = verified;
  }

  function setAmFeeBase(uint256 value) external onlyOwner {
    _amFeeBase = value;
  }

  function amFeeBase() external view returns (uint256) {
    return _amFeeBase;
  }

  function setAmFeeRatio(uint256 value) external onlyOwner {
    _amFeeRatio = value;
  }

  function amFeeRatio() external view returns (uint256) {
    return _amFeeRatio;
  }

  function _assetFee(address tokenAddress) internal view returns (uint256) {
    if (assets[tokenAddress].tokenAddress == address(0x0)) {
      return _amFeeBase * _amFeeRatio;
    } else {
      return assets[tokenAddress].feeBase * assets[tokenAddress].feeRatio;
    }
  }
}
