// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

interface IAssetManager {
  struct Asset {
    address tokenAddress;
    uint8 protocol;
    uint256 feeBase;
    uint256 feeRatio;
  }

  // events
  event AssetCreated(address indexed tokenAddress, Asset record);
  event AssetRemoved(address indexed tokenAddress);
  event AssetFeeBaseUpdated(address indexed tokenAddress, uint256 feeBase);
  event AssetFeeRatioUpdated(address indexed tokenAddress, uint256 feeRatio);
  event DefaultAssetFeeBaseUpdated(uint256 feeBase);
  event DefaultAssetFeeRatioUpdated(uint256 feeRatio);

  function asset(address tokenAddress) external view returns (Asset memory record);

  function createAsset(
    address tokenAddress,
    uint8 protocol,
    uint256 base,
    uint256 ratio
  ) external;

  function removeAsset(address tokenAddress) external;

  function setAssetFeeBase(address tokenAddress, uint256 base) external;

  function setAssetFeeRatio(address tokenAddress, uint256 ratio) external;

  function amFeeBase() external view returns (uint256);

  function setAmFeeBase(uint256 value) external;

  function amFeeRatio() external view returns (uint256);

  function setAmFeeRatio(uint256 value) external;
}
