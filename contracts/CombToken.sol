// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract CombToken is ERC20, ERC20Burnable, Ownable {
    using SafeMath for uint256;

    address payable public immutable CSG;
    uint256 public initTimestamp;
    uint256 public remainingPeriods;
    mapping (uint256 => Claim) public claims;

    constructor(
        address payable _CSG
    ) ERC20("COMB Token", "COMB") {
        CSG = _CSG;
        initTimestamp = 1664575200; // 2022-10-01 00:00:00
        remainingPeriods = 52;
        _mint(msg.sender, 100000000 * 10 ** decimals()); // minting tokens on owner address
        _transfer(msg.sender, address(this), 70000000 * 10 ** decimals()); // transfer to this contract in order to be airdropped afterwards
        _transfer(msg.sender, _CSG, 25000000 * 10 ** decimals()); // transfer to CSG contract to be sent then to LP on NFT minting trigger
    }

    struct Claim {
        uint256 period;
        address hodler;
        uint256 amount;
    }

    event ClaimRewards(uint256 period, address hodler, uint256 amount);

    // -- CRO Rewards Claiming Methods

    function claimRewards() public {
        require(initTimestamp <= block.timestamp, "Claiming is closed at the moment.");
        require(remainingPeriods > 0, "Vesting period has ended.");
        require(ERC721Enumerable(CSG).balanceOf(msg.sender) > 0, "You do not own any Shaggy.");

        uint256 claimable = _calculateClaimableAmount();
        require(claimable > 0, "You are not eligible to claim any $COMB rewards.");

        // sending claimable to the user
        IERC20(this).approve(address(this), claimable);
        IERC20(this).transferFrom(address(this), msg.sender, claimable);


    emit ClaimRewards(remainingPeriods, msg.sender, claimable);
    }

    function _calculateClaimableAmount() private returns (uint256) {
        uint256 totalAmount = 0;
        uint256 amount = SafeMath.div(7000 * 10 ** decimals(), 52);
        // foreach shaggy owned
        for (uint i = 0; i < ERC721Enumerable(CSG).balanceOf(msg.sender); i++) {
            uint tokenId = ERC721Enumerable(CSG).tokenOfOwnerByIndex(msg.sender, i);
            // check the mapping for eligibility (if doesnt exists (first claim), or last week higher then current remaining)
            if (claims[tokenId].period == 0 || claims[tokenId].period > remainingPeriods) {
                // increase reward
                uint256 shaggyAmount = claims[tokenId].period != 0 // if never claimed, not cumulative claim
                    ? SafeMath.mul(amount, claims[tokenId].period - remainingPeriods) // multiplying for difference between lastClaimWeek and remainingPeriods
                    : amount; // or not
                totalAmount = SafeMath.add(totalAmount, shaggyAmount);
                // generating claim in order to update block countdown
                uint256 _remainingPeriods = claims[tokenId].period != 0 // if never claimed, not cumulative claim
                    ? remainingPeriods // current remainingPeriods
                    : 52; // or default one (52)
                claims[tokenId] = Claim(_remainingPeriods, msg.sender, shaggyAmount);
            }
        }

        return totalAmount;
    }

    // -- Getters

    function getClaimableAmount() public view returns (uint256) {
        uint256 totalAmount = 0;
        uint256 amount = SafeMath.div(7000 * 10 ** decimals(), 52);
        // foreach shaggy owned
        for (uint i = 0; i < ERC721Enumerable(CSG).balanceOf(msg.sender); i++) {
            uint tokenId = ERC721Enumerable(CSG).tokenOfOwnerByIndex(msg.sender, i);
            // check the mapping for eligibility (if doesnt exists (first claim), or last week higher then current remaining)
            if (claims[tokenId].period == 0 || claims[tokenId].period > remainingPeriods) {
                // increase reward
                uint256 shaggyAmount = claims[tokenId].period != 0
                    ? SafeMath.mul(amount, claims[tokenId].period - remainingPeriods) // multiplying for difference between lastClaimWeek and remainingPeriods
                    : amount; // or not
                totalAmount = SafeMath.add(totalAmount, shaggyAmount);
            }
        }

        return totalAmount;
    }

    function subtractPeriod() public onlyOwner {
        require(remainingPeriods > 0, "Vesting period has ended.");
        remainingPeriods = SafeMath.sub(remainingPeriods, 1);
    }

    function updateInitTimestamp(uint256 _initTimestamp) public onlyOwner {
        initTimestamp = _initTimestamp;
    }
}
