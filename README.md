# ERC721 NFT Collection with Marketplace, HODLers claiming rewards, Utility fungible token with Liquidity Providing and Marketpac fees redistribution

## Features
- NFT Collection
  - ERC721 token are used as governance participation. They exists in a limited amount and gives you right to interact with the project's tokenomics.
- Market functions with royalties fees
  - ERC721 has been extended to implement Marketplace functions like put to sell and buy, collecting fees.
- Claiming of HODLers rewards
  - ERC721 holders will be able to claim based on their share (owned/totalSupply) from three main contracts (CronosShaggyGalaxy, CombToken, CombTokenLP) funded by a third of the minting price
- Fungible Token Utility
  - Creation of an ERC20 $COMB utility token which is pre-minted and distributed against team and contracts to give project an utility afterward.
- Fungible Token LP
  - Liquidity provide the fungible token over Uniswap protocol (VVS Finance fork in this case), collateralizing it by a third of the minting price
- Marketplace royalties redistribution
  - Contract that redistributes collected marketplace fees among team, holders and the liquidity pool (this last to increment the Coin pool size ratio against the Token one to increase value and collateralize even more)

## Live demo: https://shaggygalaxy.club
- CronosShaggyGalaxy: https://cronoscan.com/address/0x6d2da5ae4ef3766c5e327fe3af32c07ef3facd4b
- CombToken: https://cronoscan.com/address/0x64ed199498b7fa22f45c549eb5fd48edbb0d163d
- CombTokenLP: https://cronoscan.com/address/0x1501e5914951cfc90e84059aff6dcffa080fafba
- MarketplaceRoyalties: https://cronoscan.com/address/0xbae07953a68a1abed47db58558c1d8f52462e0e7
### <a href="https://docs.shaggygalaxy.club" title="Documentation" target="_blank">Documentation here</a>

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
Do not reuse this seed phrase
```bash
ganache --port 7545 --wallet.mnemonic "clever ketchup banner sausage matter blouse thrive spider water claw lazy approve" --database.dbPath "ganache-db/"
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
