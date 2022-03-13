// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import "./AssetManager.sol";
import "./AssetSwapper.sol";
import "./PxaMarket.sol";

contract Pixpress is AssetManager, AssetSwapper, PxaMarket {
  constructor(address pxaAddress) PxaMarket(pxaAddress) {}
}
