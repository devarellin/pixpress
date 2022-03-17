const chai = require("chai");
const chaiAsPromised = require("chai-as-promised");
const { deployments, getNamedAccounts, ethers } = require("hardhat");

chai.use(chaiAsPromised)
const { expect } = chai

describe("Pixpress", () => {

  const { read, execute, get, fixture } = deployments
  let owner;
  let notOwner;
  let MockPxt;
  let MockPxtDecimal;
  let Pixpress;

  beforeEach(async () => {
    const { deployer, user } = await getNamedAccounts()
    owner = deployer
    notOwner = user

    await fixture(['Mocks', 'Main']);
    MockPxt = await get('MockPxt')
    MockPxtDecimal = await read('MockPxt', 'decimals');
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
        expect(execute('Pixpress', { from: notOwner }, 'ownerDeposit', INPUT)).to.eventually.throws()
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
        expect(execute('Pixpress', { from: notOwner }, 'ownerWithdraw', withdrawAmount)).to.eventually.throws()
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
});
