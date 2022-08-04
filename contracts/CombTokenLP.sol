// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

import "./utils/VVSRouter.sol";

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}


interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function tokenByIndex(uint256 index) external view returns (uint256);
}

contract CombTokenLP {
    address private _owner;

    address payable public vvsRouter;
    address public WCRO;
    address public CronosShaggyGalaxy;
    address public COMBToken;

    uint256 public initTimestamp;
    address public tokenLP;

    mapping (uint256 => Claim) public claims;

    constructor() public {
        _owner = msg.sender;
        // contracts
        vvsRouter = payable(0x145863Eb42Cf62847A6Ca784e6416C1682b1b2Ae);
        WCRO = address(0x5C7F8A570d578ED84E63fdFA7b1eE72dEae1AE23);
        CronosShaggyGalaxy = address(0x6D2da5AE4ef3766c5E327Fe3aF32c07Ef3Facd4b);
        COMBToken = address(0x64Ed199498B7fA22F45C549Eb5fD48EDbb0D163d);
        // claim related
        initTimestamp = 1688169600; // 2023-07-01 00:00:00
        tokenLP = address(0x0); // LP token minted address, update it afterwards for hodlers claiming rewards
    }

    receive() external payable {
        assert(msg.sender == CronosShaggyGalaxy); // only accept CRO/tokens via fallback from the CSG contract
    }

    struct Claim {
        uint256 timestamp;
        address hodler;
        uint256 amount;
    }

    event ClaimRewards(uint256 timestamp, address hodler, uint256 amount);

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function provideLiquidity() public onlyOwner {
        require(address(this).balance > 0, "Contract does not have enough CRO balance.");
        uint256 COMBAmount = IERC20(COMBToken).balanceOf(address(this));
        IERC20(COMBToken).approve(address(vvsRouter), COMBAmount);
        VVSRouter(vvsRouter).addLiquidityETH{ value: address(this).balance }(
            COMBToken, // tokenB of the pool, paired with WCRO
            COMBAmount, // amountTokenDesired
            0, // amountTokenMin - we want to set unlimited slippage on Comb amount as after first distribution ppl could buy it and change pool ratio
            address(this).balance, // amountETHMin - we want to send a fixed amount of CRO
            address(this), // who receives LP tokens - leave them here, hodlers will claim them on third claim stage
            SafeMath.add(block.timestamp, 360)
        );
    }

    // -- LP Rewards Claiming Methods

    function claimRewards() public {
        require(initTimestamp <= block.timestamp, "Claiming is closed at the moment.");
        require(tokenLP != address(0x0), "LP Token address is not set.");
        require(IERC721Enumerable(CronosShaggyGalaxy).balanceOf(msg.sender) > 0, "You do not own any Shaggy.");

        uint256 claimable = _calculateClaimableAmount();
        require(claimable > 0, "You are not eligible to claim any CRO/COMB LP rewards.");

        // sending claimable to the user
        IERC20(tokenLP).approve(address(this), claimable);
        IERC20(tokenLP).transferFrom(address(this), msg.sender, claimable);

        emit ClaimRewards(block.timestamp, msg.sender, claimable);
    }

    function _calculateClaimableAmount() private returns (uint256) {
        uint256 totalAmount = 0;
        // foreach shaggy owned
        for (uint i = 0; i < IERC721Enumerable(CronosShaggyGalaxy).balanceOf(msg.sender); i++) {
            uint tokenId = IERC721Enumerable(CronosShaggyGalaxy).tokenOfOwnerByIndex(msg.sender, i);
            // check the mapping for eligibility (one-time claim, will returns 0 till first write)
            if (claims[tokenId].timestamp == 0) {
                uint256 amount = IERC20(tokenLP).balanceOf(address(this)) / IERC721Enumerable(CronosShaggyGalaxy).totalSupply();
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
        for (uint i = 0; i < IERC721Enumerable(CronosShaggyGalaxy).balanceOf(msg.sender); i++) {
            uint tokenId = IERC721Enumerable(CronosShaggyGalaxy).tokenOfOwnerByIndex(msg.sender, i);
            // check the mapping for eligibility (one-time claim, will returns 0 till first write)
            if (claims[tokenId].timestamp == 0) {
                uint256 amount = IERC20(tokenLP).balanceOf(address(this)) / IERC721Enumerable(CronosShaggyGalaxy).totalSupply();
                // increase reward
                totalAmount = SafeMath.add(totalAmount, amount);
            }
        }

        return totalAmount;
    }

    function updateVVSRouter(address _vvsRouter) public onlyOwner {
        vvsRouter = payable(_vvsRouter);
    }

    function updateInitTimestamp(uint256 _initTimestamp) public onlyOwner {
        initTimestamp = _initTimestamp;
    }

    function updateTokenLP(address _tokenLP) public onlyOwner {
        tokenLP = _tokenLP;
    }
}
