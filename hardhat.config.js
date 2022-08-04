require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-truffle5");
require('dotenv').config();

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  defaultNetwork: "hardhat", // consider that for deploy you should use ganache instead, so specify here, or during command run with --network ganache flag

  networks: {
    hardhat: {
      chainId: 1337
	  },
    goerli: {
      url: "https://goerli.infura.io/v3/"+process.env.INFURA_API_ID,
      accounts: [process.env.ETHEREUM_ACCOUNT_PRIVATE_KEY]
    }
  },

  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },

  solidity: {
    version: "0.8.4",
    settings: {
      optimizer: {
        enabled: true,
        runs: 100
      }
    }
  }
};
