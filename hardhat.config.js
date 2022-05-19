require('dotenv').config({ path: '.env' });
require("@nomiclabs/hardhat-waffle");
require('hardhat-deploy')
require("@nomiclabs/hardhat-ethers");

// Prints the Celo accounts associated with the mnemonic in .env
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.12",
  namedAccounts: {
    deployer: 0,
    userA: 1,
    userB: 2,
  },
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true,
      tags: ['local']
    },
    local: {
      url: "http://127.0.0.1:8545",
      tags: ['local']
    },
    alfajores: {
      url: "https://alfajores-forno.celo-testnet.org",
      chainId: 44787,
      accounts: [process.env.PRIVATE_KEY],
      pxtAddress: '0xd5E3bD9e68578F711407579991E01853Aa0d0B86',
      pxaMarketAddress: '0x6189901e29C36b411274b81Cc20891f65FC37a44',
      tags: ['testnet']
    },
    celo: {
      url: "https://forno.celo.org",
      chainId: 42220,
      accounts: [process.env.PRIVATE_KEY],
      tags: ['mainnet']
    },
  },
};
