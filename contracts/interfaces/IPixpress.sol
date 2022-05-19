// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

interface IPixpress {
  function setPxaMarket(address _addr) external;

  function setPxtPool(address _addr) external;

  function proposeSwap(
    address receiver,
    string memory note,
    address[] memory tokenAddresses,
    uint256[] memory amounts,
    uint256[] memory ids,
    uint8[] memory protocols,
    bool[] memory wanted
  ) external payable;

  function proposeSwapWithPxt(
    address receiver,
    string memory note,
    address[] memory tokenAddresses,
    uint256[] memory amounts,
    uint256[] memory ids,
    uint8[] memory protocols,
    bool[] memory wanted
  ) external;

  function matchSwap(
    uint256 proposeId,
    address[] memory tokenAddresses,
    uint256[] memory amounts,
    uint256[] memory ids,
    uint8[] memory protocols
  ) external payable;

  function matchSwapWithPxt(
    uint256 proposeId,
    address[] memory tokenAddresses,
    uint256[] memory amounts,
    uint256[] memory ids,
    uint8[] memory protocols
  ) external payable;

  function acceptSwap(uint256 proposeId, uint256 matchId) external;

  function swapFee(
    address[] memory tokenAddreses,
    uint8[] memory protocols,
    uint256[] memory amounts,
    bool[] memory wanted
  ) external view;

  function pause() external;

  function resume() external;
}
