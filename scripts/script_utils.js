const fs = require('fs')
const path = require('path')
const hre = require('hardhat')
const chainId = process.env.VUE_APP_DEPLOY_CONTRACT_HARDHAT_CHAINID

const deployer = {
  async logDeployer() {
    console.log("Chain ID:", chainId);
    let accounts = await ethers.getSigners();
    let d = accounts[0];
    console.log("Deploying contracts with the account:", d.address);
  },

  async publishContract(cont) {
    let frontendContractDir = path.join(__dirname, "../frontend/src/contracts");

    // libraries linking
    let libraries = {}
    let addressesPath = path.join(__dirname, "../frontend/src/contracts/addresses.json")
    if (cont.libraries.length) { // if anything has been deployed
      if (!fs.existsSync(addressesPath)) {
        console.log("ERROR Libraries not deployed yet. Abort")
        return
      }
      let raw = fs.readFileSync(addressesPath)
      if (!raw.length) {
        console.log("ERROR Libraries not deployed yet. Abort")
        return
      }
      libraries = {libraries: {}}
      let addresses = JSON.parse(raw)
      for (let i = 0; i < cont.libraries.length; i++) {
        let lib = cont.libraries[i]
        libraries.libraries[lib] = addresses[lib][chainId]
      }
    }
    // create factory
    let contract
    console.log(libraries)
    const contractFactory = await hre.ethers.getContractFactory(cont.name, libraries);
    // deploy contract
    contract = await contractFactory.deploy(...cont.constructor);
    await contract.deployed();

    // only for ethernal client
    if (cont.ethernal) {
      await hre.ethernal.push({
        name: cont.name,
        address: contract.address
      });
    }

    console.log(cont.name + " contract address: " + contract.address);

    if (!fs.existsSync(frontendContractDir)) {
      fs.mkdirSync(frontendContractDir);
    }

    const name = cont.overrideName ? cont.overrideName : cont.name
    // copy the contract JSON file to front-end and add the address field in it
    fs.copyFileSync(
      path.join(__dirname, "../artifacts/contracts/" + cont.path + cont.name + ".sol/" + cont.name + ".json"), //source
      path.join(__dirname, "../frontend/src/contracts/" + name + ".json") // destination
    );

    // check if addresses.json already exists
    let exists = fs.existsSync(path.join(__dirname, "../frontend/src/contracts/addresses.json"));

    // if not, created the file
    if (!exists) {
      fs.writeFileSync(
        path.join(__dirname, "../frontend/src/contracts/addresses.json"),
        "{}"
      );
    }

    // update the addresses.json file with the new contract address
    let addressesFile = fs.readFileSync(path.join(__dirname, "../frontend/src/contracts/addresses.json"));
    let addressesJson = JSON.parse(addressesFile);

    if (!addressesJson[name]) {
      addressesJson[name] = {};
    }

    addressesJson[name][chainId] = contract.address;

    fs.writeFileSync(
      path.join(__dirname, "../frontend/src/contracts/addresses.json"),
      JSON.stringify(addressesJson)
    );
  }
}

module.exports = deployer
