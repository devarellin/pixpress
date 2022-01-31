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
  solidity: "0.8.4",
  namedAccounts: {
    deployer: 0
  },
  networks: {
    hardhat: {
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
      tags: ['testnet']
    },
    temp: {
      url: "https://alfajores-forno.celo-testnet.org",
      chainId: 44787,
      accounts: [process.env.PRIVATE_KEY],
      migrateFrom: '0x034a738b7b7b896eF86BbC503f8b22d4FBFAB1D6',
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
