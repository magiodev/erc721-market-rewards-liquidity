# ERC721 NFT Collection

## Features
- NFT Collection
- Market functions with royalties fees
- Claiming of HODLers rewards
- Fungible Utility token LP
- Marketplace royalties redistribution

## Live demo: https://shaggygalaxy.club
- https://cronoscan.com/address/0x6d2da5ae4ef3766c5e327fe3af32c07ef3facd4b
- https://cronoscan.com/address/0x64ed199498b7fa22f45c549eb5fd48edbb0d163d
- https://cronoscan.com/address/0x1501e5914951cfc90e84059aff6dcffa080fafba
- https://cronoscan.com/address/0xbae07953a68a1abed47db58558c1d8f52462e0e7
### Soft documentation: https://docs.shaggygalaxy.club

<hr/>

### Project setup
```bash
npm install
```

### Create .env files
```bash
cp .env-template .env
```

### Deployment to ganache v7
```bash
ganache --port 7545 --wallet.mnemonic "clever ketchup banner sausage matter blouse thrive spider water claw lazy approve" --database.dbPath "/Users/stefano/Sites/cronos-shaggy-galaxy/ganache-db/"
npx hardhat run scripts/deploy.js --network ganache
```

### Deployment to a remote blockchain
```bash
npx hardhat run scripts/deploy.js --network goerli
```

### Verify on Etherscan (if remote Blockchain)
```bash
npx hardhat --network mainnet etherscan-verify --api-key <apikey>
```

### Local RPC Explorer with Ethernal (Ganache)
Start the Ethernal listener (included in hrdhat-ethernal package) in order to explore and interact with your local RPC on https://app.tryethernal.com/
```bash
ethernal listen
```
