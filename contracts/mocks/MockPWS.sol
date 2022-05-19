// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import "./interfaces/IPWS.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract MockPWS is IPWS, AccessControl {
  bytes32 public constant COORDINATOR = keccak256("COORDINATOR");

  mapping(uint256 => uint256) _weights;
  string public name = "PixelAva Weight System";

  constructor() {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(COORDINATOR, msg.sender);
  }

  function weight(uint256 id) public view returns (uint256) {
    if (_weights[id] == 0) return 1;
    return _weights[id];
  }

  function totalWeightOf(uint256[] memory _ids) public view returns (uint256) {
    uint256 total = 0;
    for (uint256 idx = 0; idx < _ids.length; idx++) {
      uint256 id = _ids[idx];
      total += weight(id);
    }
    return total;
  }

  function addWeight(uint256 id, uint256 amount) external onlyRole(COORDINATOR) {
    _weights[id] = weight(id) + amount;
    emit WeightAdded(id, amount);
  }

  function reduceWeight(uint256 id, uint256 amount) external onlyRole(COORDINATOR) {
    require(_weights[id] >= amount + 1, "PWS: insufficient weight to reduce");
    _weights[id] = _weights[id] - amount;
    emit WeightReduced(id, amount);
  }
}
