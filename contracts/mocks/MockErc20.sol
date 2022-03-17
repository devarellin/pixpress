// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockUbeswap is ERC20 {
  // token metadata

  constructor() ERC20("Ubeswap", "UBE") {
    _mint(msg.sender, 2000000000 * 10**18);
  }
}
