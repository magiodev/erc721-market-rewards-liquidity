const utils = require('./script_utils.js');
const hre = require('hardhat')

// write down contracts that you wish to deploy one-by-one
// after the run, find the ABIs and addresses in frontend/src/contracts
const contracts = [
  {
    name: "CronosShaggyGalaxy", // names only, no .sol extension
    constructor: [
      "https://arweave.net/6KcPnNp9fPOtu8_9JIEL5puFSY4bucdIp8PlX97Wtpg/", // https://arweave.net/3GIvdy-dVV_mmCfFr-TvSPaMtAD7oZHYOJW_i8zIdMA/
      '150000000000000000000', // in gwei (1000000000000000000 = 1 ETH/MATIC/CRO/{CoinSymbol})
      10000, // maxSupply
      750 // marketplace royalties in BPS (100 = 1%)
    ],
    path: '',
    libraries: [],
    ethernal: false // if using ethernal as private rpc explorer (for hardhat/ganache)
  },
  {
    name: "CombToken", // names only, no .sol extension
    constructor: {
      name: 'NFT' // THIS INJECTS this contractNameAddress as parameter
    },
    path: '',
    libraries: [],
    ethernal: false // if using ethernal as private rpc explorer (for hardhat/ganache)
  },
  {
    name: "CombTokenLP", // names only, no .sol extension
    constructor: [],
    path: '',
    libraries: [],
    ethernal: false // if using ethernal as private rpc explorer (for hardhat/ganache)
  },
  {
    name: "MarketplaceRoyalties", // names only, no .sol extension
    constructor: {
      name: 'CronosShaggyGalaxy' // THIS INJECTS this contractNameAddress as parameter
    },
    path: '',
    libraries: [],
    ethernal: false // if using ethernal as private rpc explorer (for hardhat/ganache)
  }
];


async function main() {
  await utils.logDeployer()
  for (const contract of contracts) {
    await utils.publishContract(contract);
  }
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
