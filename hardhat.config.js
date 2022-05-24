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
      pxaMarketAddress: '0x0caa875DB7B96538a716a9853FF45e44bB39aB3D',
      pxtPoolAddress: '0xf12Bae32FA1511Ef1b87A0F51d3D54eb48e38180',
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
