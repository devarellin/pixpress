// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MockCeloPunks is ERC721Enumerable, Ownable {
  using Counters for Counters.Counter;

  string private BASE_URI;
  Counters.Counter private _tokenIds;

  constructor() ERC721("CeloPunks", "CPUNK") {
    BASE_URI = "https://ipfs.io/ipfs/QmY66eL6S4HRwrPZo1SgoaP79esvzZ6455B6yFoZKnJJ2T/";
  }

  event Mint(uint256 indexed tokenId);

  function _baseURI() internal view override returns (string memory) {
    return BASE_URI;
  }

  function mint() public onlyOwner {
    _tokenIds.increment();

    uint256 id = _tokenIds.current();
    _mint(_msgSender(), id);
    emit Mint(id);
  }
}
