const chai = require("chai");
const chaiAsPromised = require("chai-as-promised");
const { deployments, getNamedAccounts, ethers } = require("hardhat");

chai.use(chaiAsPromised)
const { expect } = chai

describe("Pixpress", () => {

  const { read, execute, get, fixture } = deployments
  let owner;
  let user1;
  let user2;
  let MockPxt;
  let MockPxtDecimal;
  let MockPxa;
  let MockCeloPunks;
  let Pixpress;

  beforeEach(async () => {
    const { deployer, userA, userB } = await getNamedAccounts()
    owner = deployer
    user1 = userA
    user2 = userB

    await fixture(['Mocks', 'Main']);
    MockPxt = await get('MockPxt')
    MockPxtDecimal = await read('MockPxt', 'decimals');
    MockPxa = await get('MockPxa')
    MockCeloPunks = await get('MockCeloPunks');
    Pixpress = await get('Pixpress');
  });

  describe("PxtPool", async () => {
    it('is initiated with no balance', async () => {
      const bal = await read('Pixpress', 'balance');
      expect(bal).to.equal(0);
    });

    describe('Owner deposit', async () => {
      const INPUT = ethers.utils.parseUnits('1000', MockPxtDecimal);
      beforeEach(async () => {
        await execute('MockPxt', { from: owner }, 'approve', Pixpress.address, INPUT)
      })

      it('is owner only', async () => {
        expect(execute('Pixpress', { from: user1 }, 'ownerDeposit', INPUT)).to.eventually.throws()
      });

      describe('Owner deposit success', async () => {
        beforeEach(async () => {
          await execute('Pixpress', { from: owner }, 'ownerDeposit', INPUT)
        })

        it('increases the pool balance', async () => {
          const bal = await read('Pixpress', 'balance');
          expect(bal).to.equal(INPUT);
        });

        it('derives the correct upper window', async () => {
          const bal = await read('Pixpress', 'balance');
          const windowVal = await read('Pixpress', 'poolWindow');
          const val = await read('Pixpress', 'poolUpperBoundary');
          expect(val).to.equal(bal.mul(windowVal));
        });

        it('derives the correct lower window', async () => {
          const bal = await read('Pixpress', 'balance');
          const windowVal = await read('Pixpress', 'poolWindow');
          const val = await read('Pixpress', 'poolLowerBoundary');
          expect(val).to.equal(bal.div(windowVal));
        });

        it('derives the correct per deposit', async () => {
          const bal = await read('Pixpress', 'balance');
          const lowerBoundary = await read('Pixpress', 'poolLowerBoundary');
          const perDesposit = await read('Pixpress', 'perDeposit');
          expect(perDesposit).to.equal(bal.div(lowerBoundary));
        })

        it('derives the correct per withdraw', async () => {
          const bal = await read('Pixpress', 'balance');
          const upperBoundary = await read('Pixpress', 'poolUpperBoundary');
          const perWithdraw = await read('Pixpress', 'perDeposit');
          expect(perWithdraw).to.equal(upperBoundary.div(bal));
        })
      })
    })

    describe('Owner withdraw', () => {
      const INIT_BALANCE = ethers.utils.parseUnits('1000', MockPxtDecimal);
      beforeEach(async () => {
        await execute('MockPxt', { from: owner }, 'approve', Pixpress.address, INIT_BALANCE)
        await execute('Pixpress', { from: owner }, 'ownerDeposit', INIT_BALANCE)
      })

      it('cannot withdraw insufficient balance', async () => {
        const withdrawAmount = ethers.utils.parseUnits('2000', MockPxtDecimal);
        try {
          await execute('Pixpress', { from: owner }, 'ownerWithdraw', withdrawAmount)
        } catch (e) {
          expect(e).to.be.an('error')
        }
      });


      it('is owner only', async () => {
        const withdrawAmount = ethers.utils.parseUnits('500', MockPxtDecimal);
        expect(execute('Pixpress', { from: user1 }, 'ownerWithdraw', withdrawAmount)).to.eventually.throws()
      });

      describe('Owner withdraw success', () => {
        const withdrawAmount = ethers.utils.parseUnits('500', MockPxtDecimal);
        beforeEach(async () => {
          await execute('Pixpress', { from: owner }, 'ownerWithdraw', withdrawAmount)
        })

        it('decrease the pool balance', async () => {
          const bal = await read('Pixpress', 'balance');
          expect(bal).to.equal(INIT_BALANCE.sub(withdrawAmount));
        });

        it('derives the correct upper window', async () => {
          const bal = await read('Pixpress', 'balance');
          const windowVal = await read('Pixpress', 'poolWindow');
          const val = await read('Pixpress', 'poolUpperBoundary');
          expect(val).to.equal(bal.mul(windowVal));
        });

        it('derives the correct lower window', async () => {
          const bal = await read('Pixpress', 'balance');
          const windowVal = await read('Pixpress', 'poolWindow');
          const val = await read('Pixpress', 'poolLowerBoundary');
          expect(val).to.equal(bal.div(windowVal));
        });

        it('derives the correct per deposit', async () => {
          const bal = await read('Pixpress', 'balance');
          const lowerBoundary = await read('Pixpress', 'poolLowerBoundary');
          const perDesposit = await read('Pixpress', 'perDeposit');
          expect(perDesposit).to.equal(bal.div(lowerBoundary));
        })

        it('derives the correct per withdraw', async () => {
          const bal = await read('Pixpress', 'balance');
          const upperBoundary = await read('Pixpress', 'poolUpperBoundary');
          const perWithdraw = await read('Pixpress', 'perDeposit');
          expect(perWithdraw).to.equal(upperBoundary.div(bal));
        })
      })
    })
  })

  describe('Main contract', () => {
    beforeEach(async () => {
      // prepare NFTs for accounts
      for (let i = 0; i < 6; i++) {
        await execute('MockPxa', { from: owner }, 'mint')
        await execute('MockCeloPunks', { from: owner }, 'mint')
        if (i > 2) {
          await execute('MockPxa', { from: owner }, 'safeTransferFrom(address,address,uint256)', owner, user1, i + 1);
          await execute('MockCeloPunks', { from: owner }, 'safeTransferFrom(address,address,uint256)', owner, user1, i + 1);
        }
      }
      await execute('MockPxa', { from: owner }, 'setApprovalForAll', Pixpress.address, true)
      await execute('MockCeloPunks', { from: owner }, 'setApprovalForAll', Pixpress.address, true)
      await execute('MockPxa', { from: user1 }, 'setApprovalForAll', Pixpress.address, true)
      await execute('MockCeloPunks', { from: user1 }, 'setApprovalForAll', Pixpress.address, true)
    })

    describe('Propose order', () => {
      let receiver
      let note
      let tokenAddresses
      let amounts
      let ids
      let protocols
      let wanted
      beforeEach(async () => {
        receiver = user1
        note = 'want pxa'
        tokenAddresses = [MockCeloPunks.address, MockPxa.address]
        amounts = [ethers.BigNumber.from(1), ethers.BigNumber.from(1)]
        ids = [ethers.BigNumber.from(1), ethers.BigNumber.from(5)]
        protocols = [2, 2]
        wanted = [false, true]
      })


      it('requires service fee', async () => {
        expect(execute('Pixpress', { from: owner }, 'proposeSwap', receiver, note, tokenAddresses, amounts, ids, protocols, wanted)).to.eventually.rejected
      })

      it('create a new propose order', async () => {
        const fee = await read('Pixpress', 'calcSwapFee', tokenAddresses, protocols, amounts, wanted)
        await execute('Pixpress', { from: owner, value: fee }, 'proposeSwap', receiver, note, tokenAddresses, amounts, ids, protocols, wanted)
        const record = await read('Pixpress', 'proposeRecord', 1)
        expect(record.receiver).to.equal(receiver);
        expect(record.note).to.equal(note);
        expect(record.tokenAddresses).to.eql(tokenAddresses);
        expect(record.amounts).to.eql(amounts);
        expect(record.ids).to.eql(ids);
        expect(record.protocols).to.eql(protocols);
        expect(record.wanted).to.eql(wanted);
      })
    })

    describe('Match order without receiver', () => {
      // propose order meta
      let receiver
      let note
      let tokenAddresses
      let amounts
      let ids
      let protocols
      let wanted
      let proposeFee

      // match order meta
      let proposeId;
      let matchTokenAddresses;
      let matchAmounts;
      let matchIds;
      let matchProtocols;
      beforeEach(async () => {
        receiver = ethers.constants.AddressZero
        note = 'want pxa'
        tokenAddresses = [MockCeloPunks.address, MockPxa.address]
        amounts = [ethers.BigNumber.from(1), ethers.BigNumber.from(1)]
        ids = [ethers.BigNumber.from(1), ethers.BigNumber.from(5)]
        protocols = [2, 2]
        wanted = [false, true]
        // create a propose order
        proposeFee = await read('Pixpress', 'calcSwapFee', tokenAddresses, protocols, amounts, wanted)
        await execute('Pixpress', { from: owner, value: proposeFee }, 'proposeSwap', receiver, note, tokenAddresses, amounts, ids, protocols, wanted)

        // prepare match order meta
        proposeId = 1;
        matchTokenAddresses = [MockPxa.address, MockPxa.address]
        matchAmounts = [ethers.BigNumber.from(1), ethers.BigNumber.from(1)]
        matchIds = [ethers.BigNumber.from(4), ethers.BigNumber.from(5)]
        matchProtocols = [2, 2]
      })

      it('create a new match order', async () => {
        const fee = await read('Pixpress', 'calcSwapFee', matchTokenAddresses, matchProtocols, matchAmounts, new Array(matchTokenAddresses.length).fill(false))
        await execute('Pixpress', { from: owner, value: fee }, 'matchSwap', proposeId, matchTokenAddresses, matchAmounts, matchIds, matchProtocols)
        const record = await read('Pixpress', 'matchRecord', 1)
      })
    })

    describe('Match order', () => {
      // propose order meta
      let receiver
      let note
      let tokenAddresses
      let amounts
      let ids
      let protocols
      let wanted
      let proposeFee

      // match order meta
      let proposeId;
      let matchTokenAddresses;
      let matchAmounts;
      let matchIds;
      let matchProtocols;
      beforeEach(async () => {
        receiver = user1
        note = 'want pxa'
        tokenAddresses = [MockCeloPunks.address, MockPxa.address]
        amounts = [ethers.BigNumber.from(1), ethers.BigNumber.from(1)]
        ids = [ethers.BigNumber.from(1), ethers.BigNumber.from(5)]
        protocols = [2, 2]
        wanted = [false, true]
        // create a propose order
        proposeFee = await read('Pixpress', 'calcSwapFee', tokenAddresses, protocols, amounts, wanted)
        await execute('Pixpress', { from: owner, value: proposeFee }, 'proposeSwap', receiver, note, tokenAddresses, amounts, ids, protocols, wanted)

        // prepare match order meta
        proposeId = 1;
        matchTokenAddresses = [MockPxa.address, MockPxa.address]
        matchAmounts = [ethers.BigNumber.from(1), ethers.BigNumber.from(1)]
        matchIds = [ethers.BigNumber.from(4), ethers.BigNumber.from(5)]
        matchProtocols = [2, 2]
      })


      it('requires service fee', async () => {
        expect(execute('Pixpress', { from: owner }, 'matchSwap', proposeId, matchTokenAddresses, matchAmounts, matchIds, matchProtocols)).to.eventually.rejected
      })

      it('cannot create a new match order if receiver not match', async () => {
        const fee = await read('Pixpress', 'calcSwapFee', matchTokenAddresses, matchProtocols, matchAmounts, new Array(matchTokenAddresses.length).fill(false))
        try {
          await execute('Pixpress', { from: owner, value: fee }, 'matchSwap', proposeId, matchTokenAddresses, matchAmounts, matchIds, matchProtocols)
        } catch (e) {
          expect(e).to.be.an('error')
        }

      })

      it('create a new match order', async () => {
        const fee = await read('Pixpress', 'calcSwapFee', matchTokenAddresses, matchProtocols, matchAmounts, new Array(matchTokenAddresses.length).fill(false))
        await execute('Pixpress', { from: user1, value: fee }, 'matchSwap', proposeId, matchTokenAddresses, matchAmounts, matchIds, matchProtocols)
        const record = await read('Pixpress', 'matchRecord', 1)
        expect(record.proposeId).to.equal(proposeId);
        expect(record.tokenAddresses).to.eql(matchTokenAddresses);
        expect(record.amounts).to.eql(matchAmounts);
        expect(record.ids).to.eql(matchIds);
        expect(record.protocols).to.eql(matchProtocols);
      })
    })

    describe('Accept swap order', () => {
      // propose order meta
      let receiver
      let note
      let tokenAddresses
      let amounts
      let ids
      let protocols
      let wanted
      let proposeFee

      // match order meta
      let proposeId;
      let matchTokenAddresses;
      let matchAmounts;
      let matchIds;
      let matchProtocols;
      let matchFee;
      let matchId
      beforeEach(async () => {
        receiver = user1
        note = 'want pxa'
        tokenAddresses = [MockCeloPunks.address, MockPxa.address]
        amounts = [ethers.BigNumber.from(1), ethers.BigNumber.from(1)]
        ids = [ethers.BigNumber.from(1), ethers.BigNumber.from(5)]
        protocols = [2, 2]
        wanted = [false, true]
        // create a propose order
        proposeFee = await read('Pixpress', 'calcSwapFee', tokenAddresses, protocols, amounts, wanted)
        await execute('Pixpress', { from: owner, value: proposeFee }, 'proposeSwap', receiver, note, tokenAddresses, amounts, ids, protocols, wanted)

        // create a match order
        proposeId = 1;
        matchTokenAddresses = [MockPxa.address, MockPxa.address]
        matchAmounts = [ethers.BigNumber.from(1), ethers.BigNumber.from(1)]
        matchIds = [ethers.BigNumber.from(4), ethers.BigNumber.from(5)]
        matchProtocols = [2, 2]
        matchFee = await read('Pixpress', 'calcSwapFee', matchTokenAddresses, matchProtocols, matchAmounts, new Array(matchTokenAddresses.length).fill(false))
        await execute('Pixpress', { from: user1, value: matchFee }, 'matchSwap', proposeId, matchTokenAddresses, matchAmounts, matchIds, matchProtocols)
        matchId = 1;
      })


      it('swap token between proposer and matcher', async () => {
        await execute('Pixpress', { from: owner }, 'acceptSwap', proposeId, matchId);
        expect(read('MockCeloPunks', 'ownerOf', 1)).to.eventually.equal(user1);
        expect(read('MockPxa', 'ownerOf', 4)).to.eventually.equal(owner);
        expect(read('MockPxa', 'ownerOf', 5)).to.eventually.equal(owner);
      })

      it('reward both user with PXT liquidity', async () => {
        const INPUT = ethers.utils.parseUnits('10000', MockPxtDecimal);
        await execute('MockPxt', { from: owner }, 'approve', Pixpress.address, INPUT)
        await execute('Pixpress', { from: owner }, 'ownerDeposit', INPUT)
        const totalReward = await read('Pixpress', 'perWithdraw');
        await execute('Pixpress', { from: owner }, 'acceptSwap', proposeId, matchId);
        const reward = await read('MockPxt', 'balanceOf', user1);
        expect(totalReward.div(ethers.BigNumber.from(2))).to.equal(reward)
      })
    })
  })
});
