// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PixelAva is ERC721Enumerable, Ownable {
  using Counters for Counters.Counter;

  string private BASE_URI;
  mapping(address => uint256) private _mainTokenIds;
  Counters.Counter private _tokenIds;
  mapping(uint256 => string) private _names;

  constructor(string memory baseUri) ERC721("PixelAvaV2", "PXA") {
    BASE_URI = baseUri;
  }

  event Mint(uint256 indexed tokenId, uint8[16][16] matrix, string[5] colors);
  event Name(uint256 indexed tokenId, string name);

  function setBaseURI(string memory baseURI) public onlyOwner {
    BASE_URI = baseURI;
  }

  function _baseURI() internal view override returns (string memory) {
    return BASE_URI;
  }

  function mainTokenId() public view returns (uint256) {
    return _mainTokenIds[_msgSender()];
  }

  function setMainTokenId(uint256 tokenId) public {
    require(_exists(tokenId), "ERC721: operator query for nonexistent token");
    address owner = ERC721.ownerOf(tokenId);
    require(_msgSender() == owner, "PixelAva: only owner can set this token to their main token");
    require(tokenId != _mainTokenIds[_msgSender()], "PixelAva: this token id is your main token id");
    _mainTokenIds[_msgSender()] = tokenId;
  }

  function tokenName(uint256 tokenId) public view returns (string memory) {
    require(_exists(tokenId), "ERC721: operator query for nonexistent token");
    return _names[tokenId];
  }

  function setTokenName(uint256 tokenId, string memory name) public {
    require(_exists(tokenId), "ERC721: operator query for nonexistent token");
    address owner = ERC721.ownerOf(tokenId);
    require(_msgSender() == owner, "PixelAva: only owner can name the token");
    _setTokenName(tokenId, name);
  }

  function _setTokenName(uint256 tokenId, string memory name) private {
    _names[tokenId] = name;
    emit Name(tokenId, name);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override {
    super._beforeTokenTransfer(from, to, tokenId);
    if (tokenId == _mainTokenIds[from]) {
      delete _mainTokenIds[from];
    }
  }

  function mint(uint8[16][16] memory matrix, string[5] memory colors) public onlyOwner {
    _tokenIds.increment();

    uint256 id = _tokenIds.current();
    _mint(_msgSender(), id);
    emit Mint(id, matrix, colors);
  }
}
