// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CronosShaggyGalaxy is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Strings for uint256;

    // General
    Counters.Counter private _tokenIdCounter;
    string public baseTokenURI;
    uint256 public maxSupply;
    uint256 public mintPrice;
    uint256 public tokensRemainingToAssign;
    mapping(uint256 => uint256) private assignOrders;

    // Marketplace
    uint256 public volume;
    mapping (uint256 => Sale) public tokensForSale;
    address public ownerTeam;
    uint256 public royaltiesBips;

    // Rewards
    address public combToken;
    address public liquidityPool;
    address public marketplaceRoyalties;
    uint256 public initTimestamp;
    uint256 public claimInterval;
    mapping (uint256 => Claim) public claims;

    constructor(
        string memory _baseURIValue,
        uint256 _mintPrice,
        uint256 _maxSupply,
        uint256 _royaltiesBips
    ) ERC721("CronosShaggyGalaxy", "CSG") {
        baseTokenURI = _baseURIValue;
        mintPrice = _mintPrice;
        maxSupply = _maxSupply;
        tokensRemainingToAssign = _maxSupply;

        ownerTeam = address(0xBDaAB06205C6230801527B27B3f1DC1913293B1E);
        royaltiesBips = _royaltiesBips;

        combToken = address(0x0);
        liquidityPool = address(0x0);
        marketplaceRoyalties = address(0x0);
        initTimestamp = 1656705600; // 2022-07-01 20:00:00 UTC
        claimInterval = 604800; // 604800 seconds = 1 week
        _pause();
    }

    receive() external payable {} // needed to accumulate marketplace distribution

    // -- Structures

    struct Sale {
        bool isForSale;
        uint256 tokenId;
        address seller;
        uint256 price;
    }

    struct Claim {
        uint256 timestamp;
        address hodler;
        uint256 amount;
    }

    // -- Events

    event TokensMinted(uint[] tokenIds, address buyer);
    event UpdateMintPrice(uint256 mintPrice, address owner);
    event PutTokenForSale(uint256 tokenId, uint256 price, address from);
    event TokenBought(uint tokenId, uint value, uint sellerRevenue, uint royalties, address seller, address buyer);
    event TokenNoLongerForSale(uint256 tokenId, address from);
    event ClaimRewards(uint256 timestamp, address hodler, uint256 amount);

    // -- Modifiers

    modifier onlyTradableToken (address from, uint256 tokenId) {
        require(_exists(tokenId), "CronosShaggyGalaxy: TokenId does not exist");
        require(ownerOf(tokenId) == from, "CronosShaggyGalaxy: Token does not belong to user");
        _;
    }

    // -- Minting Methods

    function mintToken(uint256 amount) public payable {
        require(initTimestamp <= block.timestamp, "Minting is closed at the moment.");
        require(amount <= 10, "CronosShaggyGalaxy: You cannot mint more than 10 NFTs per time.");
        require(getMintPrice(amount) == msg.value, "CronosShaggyGalaxy: Payment amount is incorrect.");
    }

    function _mintToken(uint256 amount, address recipient, bool random) private {
        require(totalSupply() < maxSupply, "CronosShaggyGalaxy: Sale has already ended.");
        require(amount > 0, "CronosShaggyGalaxy: You cannot mint 0 Nfts.");
        require(SafeMath.add(totalSupply(), amount) <= maxSupply, "CronosShaggyGalaxy: Exceeds maximum supply. Please try to mint less Nfts.");

        uint[] memory tokenIdsBought = new uint[](amount);

        for (uint i = 0; i < amount; i++) {
            uint256 randIndex = (random ? _random(tokensRemainingToAssign) : totalSupply()) % tokensRemainingToAssign;
            uint256 tokenIndex = SafeMath.add(_fillAssignOrder(--tokensRemainingToAssign, randIndex), 1);
            _tokenIdCounter.increment();
            _safeMint(recipient, tokenIndex);
            _setTokenURI(tokenIndex, string(abi.encodePacked(Strings.toString(tokenIndex), ".json")));
            tokenIdsBought[i] = tokenIndex;
            // generating first dummy claim in order to set block countdown
            claims[tokenIndex] = Claim(block.timestamp, msg.sender, 0);
        }

        // dividing by 3 the msg.value
        uint256 distributedValue = msg.value.div(3);
        // first third to owner
        (bool success1,) = ownerTeam.call{value: SafeMath.mul(distributedValue)}("");
        require(success1);
        // second third to address for CRO/$COMB LP
        (bool success2,) = liquidityPool.call{value: distributedValue}("");
        require(success2);
        uint256 combAmount = SafeMath.mul(2500 * 10 ** ERC20(combToken).decimals(), amount);
        ERC20(combToken).approve(address(this), combAmount);
        ERC20(combToken).transferFrom(address(this), liquidityPool, combAmount);
        // last third left in this contract for rewards claiming

        emit TokensMinted(tokenIdsBought, _msgSender());
    }

    function _random(uint256 number) internal view returns(uint256) {
        return uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp + block.difficulty + block.gaslimit + block.number +
                    ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / block.timestamp) +
                    ((uint256(keccak256(abi.encodePacked(msg.sender)))) / block.timestamp)
                )
            )
        ) / number;
    }

    function _fillAssignOrder(uint256 orderA, uint256 orderB) internal returns(uint256) {
        uint256 temp = orderA;
        if (assignOrders[orderA] > 0) temp = assignOrders[orderA];
        assignOrders[orderA] = orderB;
        if (assignOrders[orderB] > 0) assignOrders[orderA] = assignOrders[orderB];
        assignOrders[orderB] = temp;
        return assignOrders[orderA];
    }

    // -- Marketplace Methods

    function putTokenForSale(uint256 tokenId, uint256 price) public onlyTradableToken(_msgSender(), tokenId) {
        require(price != 0, "CronosShaggyGalaxy: Cannot put zero as a price");

        tokensForSale[tokenId] = Sale(true, tokenId, _msgSender(), price);
        emit PutTokenForSale(tokenId, price, _msgSender());
    }

    function buyToken(uint256 tokenId) payable public {
        Sale memory offer = tokensForSale[tokenId];
        require(_exists(tokenId), "CronosShaggyGalaxy: TokenId does not exist");
        require(offer.isForSale, "CronosShaggyGalaxy: No Sale");
        require(msg.value == offer.price, "CronosShaggyGalaxy: Incorrect amount");
        require(ownerOf(tokenId) == offer.seller, "CronosShaggyGalaxy: Not seller"); // This is not possible but just in case
        address seller = offer.seller;

        // Transfer the NFT, this will automatically remove it from the marketplace
        _safeTransfer(seller, _msgSender(), tokenId, "");
        // Calculating royalties
        (uint256 amountAfterRoyalties, uint256 royaltiesAmount) = _calculateMarketplaceRoyalties(msg.value, royaltiesBips);

        // increasing marketplace volume
        volume += msg.value;
        // sending amount less fees to seller
        (bool success1,) = seller.call{value: amountAfterRoyalties}("");
        require(success1);
        // sending fees to marketplaceRoyalties contract
        (bool success2,) = marketplaceRoyalties.call{value: royaltiesAmount}("");
        require(success2);

        emit TokenBought(tokenId, msg.value, amountAfterRoyalties, royaltiesAmount, seller, _msgSender());
    }

    function _calculateMarketplaceRoyalties(uint256 amount, uint256 _royaltiesBips) internal pure returns (uint256 amountAfterRoyalties, uint256 royaltiesAmount) {
        royaltiesAmount = amount.mul(_royaltiesBips).div(10000);
        amountAfterRoyalties = amount.sub(royaltiesAmount);
    }

    function tokenNoLongerForSale(uint256 tokenId) public onlyTradableToken(_msgSender(), tokenId) {
        tokensForSale[tokenId] = Sale(false, tokenId, _msgSender(), 0);
        emit TokenNoLongerForSale(tokenId, _msgSender());
    }

    // -- CRO Rewards Claiming Methods

    function claimRewards() public {
        require(initTimestamp <= block.timestamp, "Claiming is closed at the moment.");
        require(balanceOf(msg.sender) > 0, "You do not own any Shaggy.");

        uint256 claimable = _calculateClaimableAmount();
        require(claimable > 0, "You are not eligible to claim any CRO rewards.");

        // sending claimable to the user
        (bool success,) = msg.sender.call{value: claimable}("");
        require(success);

        emit ClaimRewards(block.timestamp, msg.sender, claimable);
    }

    function _calculateClaimableAmount() private returns (uint256) {
        uint256 totalAmount = 0;
        // foreach shaggy owned
        for (uint i = 0; i < balanceOf(msg.sender); i++) {
            uint tokenId = tokenOfOwnerByIndex(msg.sender, i);
            // check the mapping for eligibility, cannot be zero (should never be) && lastClaimTimestamp+claimInterval less or equal currentTimestamp
            if (claims[tokenId].timestamp != 0 && SafeMath.add(claims[tokenId].timestamp, claimInterval) <= block.timestamp) {
                // currentBalance divided currentTotalSupply
                uint256 amount = SafeMath.div(address(this).balance, totalSupply());
                // increase reward
                totalAmount = SafeMath.add(totalAmount, amount);
                // generating claim in order to update block countdown
                claims[tokenId] = Claim(block.timestamp, msg.sender, SafeMath.add(claims[tokenId].amount, amount));
            }
        }

        return totalAmount;
    }

    function getClaimableAmount() public view returns (uint256) {
        uint256 totalAmount = 0;
        // foreach shaggy owned
        for (uint i = 0; i < balanceOf(msg.sender); i++) {
            uint tokenId = tokenOfOwnerByIndex(msg.sender, i);
            // check the mapping for eligibility, cannot be zero (should never be) && lastClaimTimestamp+claimInterval less or equal currentTimestamp
            if (claims[tokenId].timestamp != 0 && SafeMath.add(claims[tokenId].timestamp, claimInterval) <= block.timestamp) {
                uint256 amount = SafeMath.div(address(this).balance, totalSupply());
                // increase reward
                totalAmount = SafeMath.add(totalAmount, amount);
            }
        }

        return totalAmount;
    }

    // -- Getters

    function getMintPrice(uint256 amount) public view returns (uint256) {
        return amount * mintPrice;
    }

    function getOnSaleTokenIds(uint256 start, uint256 end) public view returns (uint256[] memory tokenIds, address[] memory sellers, uint256[] memory prices) {
        uint256 max = maxSupply > end ? end : maxSupply;

        uint256 count = 0;
        for (uint i = start; i < max; i++) {
            if (tokensForSale[i].isForSale) {
                count++;
            }
        }

        uint256[] memory _onSaleTokenIds = new uint[](count);
        address[] memory _sellers = new address[](count);
        uint256[] memory _prices = new uint256[](count);

        uint256 counter = 0;
        for (uint i = start; i < end; i++) {
            if (tokensForSale[i].isForSale) {
                _onSaleTokenIds[counter] = i;
                _sellers[counter] = tokensForSale[i].seller;
                _prices[counter] = tokensForSale[i].price;
                counter++;
            }
        }

        return (_onSaleTokenIds, _sellers, _prices);
    }

    // -- Owner

    function updateBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function updateMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
        emit UpdateMintPrice(_mintPrice, _msgSender());
    }

    function updateCombToken(address _combToken) public onlyOwner {
        combToken = _combToken;
    }

    function updateLiquidityPool(address _liquidityPool) public onlyOwner {
        liquidityPool = _liquidityPool;
    }

    function updateMarketplaceRoyalties(address _marketplaceRoyalties) public onlyOwner {
        marketplaceRoyalties = _marketplaceRoyalties;
    }

    function updateInitTimestamp(uint256 _initTimestamp) public onlyOwner {
        initTimestamp = _initTimestamp;
    }

    function updateClaimInterval(uint256 _claimInterval) public onlyOwner {
        claimInterval = _claimInterval;
    }

    function adminMintToken(uint256 amount, address recipient) public onlyOwner {
        require(msg.sender == ownerTeam);
        _mintToken(amount, recipient, true);
    }

    function adminMintTokenNoRandomness(uint256 amount, address recipient) public onlyOwner {
        _mintToken(amount, recipient, false);
    }

    // -- Overwriting this method for Sale creation

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal whenNotPaused override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);

        tokensForSale[tokenId] = Sale(false, tokenId, address(0), 0);
    }

    // -- Overwriting this methods for Pause/Unpause the contract

    function pause() public onlyOwner {
        _pause();
    }
    function unpause() public onlyOwner {
        require(combToken != address(0x0));
        require(liquidityPool != address(0x0));
        require(marketplaceRoyalties != address(0x0));
        _unpause();
    }

    // -- Solidity overrides

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
