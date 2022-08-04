// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./utils/IWETH.sol";

contract MarketplaceRoyalties is Ownable {
    using SafeMath for uint256;

    address payable public immutable CSG; // contract, as hodlers reward
    address payable public LP; // sending increases value of WCRO against COMB, pushing COMB price up
    address public WCRO;

    constructor(
        address payable _CSG
    ) {
        CSG = payable(_CSG);
        LP = payable(0x0);
        WCRO = address(0x5C7F8A570d578ED84E63fdFA7b1eE72dEae1AE23);
    }

    receive() external payable {}

    event DistributeRoyalties(uint256 owner, uint256 cronosShaggyGalaxy, uint256 liquidityPool);

    function distributeRoyalties() public {
        require(LP != address(0x0),"LiquidityPool address has not been set yet, likely meaning that first initial supply has not been provided.");

        // setting total as current CRO balance
        uint256 amount = address(this).balance;
        // sending amount less fees to seller
        uint256 ownerAmount = amount.mul(2666).div(10000); // 2% of sell price if royalties 7.5% (26% of 100% royalties)
        (bool success1,) = owner().call{value: ownerAmount}("");
        require(success1);

        // sending to CSG contract for hodlers claim
        uint256 CSGAmount = amount.mul(3334).div(10000); // 2.5% of sell price if royalties 7.5% (33.33% of 100% royalties)
        (bool success2,) = CSG.call{value: CSGAmount}("");
        require(success2);

        // wrapping to WCRO and sending to LP pair address (not CombTokenLP.sol contract)
        uint256 LPAmount = SafeMath.sub(amount, ownerAmount + CSGAmount); // 3% of sell price if royalties 7.5% (40% of 100% royalties)
        IWETH(WCRO).deposit{value : LPAmount}();
        assert(IWETH(WCRO).transfer(LP, LPAmount));

        emit DistributeRoyalties(ownerAmount, CSGAmount, LPAmount);
    }

    function updateLP(address payable _LP) public onlyOwner {
        LP = _LP;
    }
}
