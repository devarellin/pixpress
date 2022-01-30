const { expect } = require("chai");
const { ethers } = require("hardhat");

const BASE_URI = 'https://pixelava.com/api/metadata/'

const MATRIX = [
  [0, 0, 5, 5, 5, 0, 0, 0, 0, 0, 0, 5, 5, 5, 0, 0],
  [0, 5, 3, 2, 2, 5, 5, 5, 5, 5, 5, 2, 2, 3, 5, 0],
  [0, 5, 5, 3, 3, 2, 2, 2, 2, 2, 2, 3, 3, 5, 5, 0],
  [5, 2, 5, 3, 3, 4, 4, 3, 3, 4, 4, 3, 3, 5, 2, 5],
  [5, 4, 5, 4, 4, 5, 5, 4, 4, 5, 5, 4, 4, 5, 4, 5],
  [0, 5, 3, 5, 5, 0, 0, 5, 5, 0, 0, 5, 5, 3, 5, 0],
  [0, 0, 5, 0, 0, 5, 0, 0, 0, 0, 5, 0, 0, 5, 0, 0],
  [0, 0, 0, 5, 5, 2, 5, 5, 5, 5, 2, 5, 5, 0, 0, 0],
  [0, 0, 5, 2, 5, 4, 5, 2, 2, 5, 4, 5, 2, 5, 0, 0],
  [0, 5, 5, 4, 5, 5, 2, 4, 4, 2, 5, 5, 4, 5, 5, 0],
  [5, 2, 5, 5, 5, 2, 3, 5, 5, 3, 2, 5, 5, 5, 2, 5],
  [5, 3, 2, 2, 5, 3, 3, 3, 3, 3, 3, 5, 2, 2, 3, 5],
  [5, 4, 3, 3, 2, 3, 3, 5, 5, 3, 3, 2, 3, 3, 4, 5],
  [0, 5, 3, 3, 3, 3, 3, 2, 2, 3, 3, 3, 3, 3, 5, 0],
  [5, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 3, 5],
  [0, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 0]
]

const COLOR = [
  "#78e2bd",
  "#99e73f",
  "#80d81b",
  "#b1ed6c",
  "#206bdf",
]

let pixelAva;
let user;

describe("PixelAva", async () => {

  beforeEach(async () => {
    const PixelAva = await ethers.getContractFactory('PixelAva');
    pixelAva = await PixelAva.deploy(BASE_URI);
    await pixelAva.deployed();

    [owner, user] = await ethers.getSigners();
  });

  it('should have a correct name', async () => {
    const name = await pixelAva.name();
    expect(name).to.equal('PixelAva');
  });

  it('should have correct symbol', async () => {
    const symbol = await pixelAva.symbol();
    expect(symbol).to.equal('PXA');
  });

  it('should have 0 initial total supply', async () => {
    const totalSupply = await pixelAva.totalSupply();
    expect(totalSupply).to.equal(0);
  });

  describe('Mint', async () => {
    it('should not allow user that is not owner to mint', async () => {
      try {
        await pixelAva.connect(user).mint(MATRIX, COLOR)
      } catch (e) {
        expect(e).to.be.an('error')
      } finally {
        const totalSupply = await pixelAva.totalSupply();
        expect(totalSupply).to.equal(0);
      }
    })

    it('should have 1 total supply after minted', async () => {
      await pixelAva.mint(MATRIX, COLOR)
      const totalSupply = await pixelAva.totalSupply();
      expect(totalSupply).to.equal(1);
    });

    it('should have minted token with correct token URI', async () => {
      await pixelAva.mint(MATRIX, COLOR)
      const tokenURI = await pixelAva.tokenURI(1);
      expect(tokenURI).to.equal(`${BASE_URI}1`);
    });

    it('should emit Mint event after minted', async () => {
      const tx = await pixelAva.mint(MATRIX, COLOR)
      const receipt = await tx.wait()
      const log = pixelAva.interface.parseLog(receipt.logs[1])
      const { tokenId, matrix, colors } = log.args
      expect(tokenId).to.equal(1)
      expect(matrix).to.deep.equal(MATRIX)
      expect(colors).to.deep.equal(COLOR)
    })
  })

  describe('TokenName', async () => {
    it('should not allow user that is not owner to set token name', async () => {
      await pixelAva.mint(MATRIX, COLOR)
      try {
        await pixelAva.connect(user).setTokenName(1, 'Perry')
      } catch (e) {
        expect(e).to.be.an('error')
      } finally {
        const tokenName = await pixelAva.tokenName(1);
        expect(tokenName).to.equal('');
      }
    })

    it('should set token name correct', async () => {
      await pixelAva.mint(MATRIX, COLOR)
      await pixelAva.setTokenName(1, 'Perry')
      const tokenName = await pixelAva.tokenName(1)
      expect(tokenName).to.equal('Perry')
    })

    it('should emit Name event after named', async () => {
      await pixelAva.mint(MATRIX, COLOR)
      const tx = await pixelAva.setTokenName(1, 'Perry')
      const receipt = await tx.wait()
      const log = pixelAva.interface.parseLog(receipt.logs[0])
      const { tokenId, name } = log.args
      expect(tokenId).to.equal(1)
      expect(name).to.equal('Perry')
    })
  })

  describe('MainToken', async () => {
    it('should not allow user that is not owner to set main token', async () => {
      await pixelAva.mint(MATRIX, COLOR)
      try {
        await pixelAva.connect(user).setMainTokenId(1)
      } catch (e) {
        expect(e).to.be.an('error')
      } finally {
        const mainToken = await pixelAva.mainTokenId();
        expect(mainToken).to.equal(0);
      }
    })

    it('should be able to set main token', async () => {
      await pixelAva.mint(MATRIX, COLOR)
      await pixelAva.setMainTokenId(1)
      const mainToken = await pixelAva.mainTokenId()
      expect(mainToken).to.equal(1)
    })

    it('should be reset after transfer', async () => {
      await pixelAva.mint(MATRIX, COLOR)
      await pixelAva.setMainTokenId(1)
      const mainToken = await pixelAva.mainTokenId()
      expect(mainToken).to.equal(1)
      await pixelAva['safeTransferFrom(address,address,uint256)'](owner.address, user.address, 1)
      const mainTokenAfter = await pixelAva.mainTokenId()
      expect(mainTokenAfter).to.equal(0)
    })
  })
});
