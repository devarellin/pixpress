// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.12;

interface IPWS {
  event WeightAdded(uint256 indexed id, uint256 amount);
  event WeightReduced(uint256 indexed id, uint256 amount);

  function weight(uint256 id) external view returns (uint256);

  function totalWeightOf(uint256[] memory _ids) external view returns (uint256);

  function addWeight(uint256 id, uint256 amount) external;

  function reduceWeight(uint256 id, uint256 amount) external;
}
