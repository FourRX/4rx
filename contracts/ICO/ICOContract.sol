//SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "../PancakeSwap/IPancakeV2Factory.sol";
import "../PancakeSwap/IPancakeV2Pair.sol";
import "../PancakeSwap/IPancakeV2Router01.sol";
import "../PancakeSwap/IPancakeV2Router02.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../4RX/IFourRXToken.sol";

contract ICOContract is Ownable {
    using SafeMath for uint;

    uint public constant MIN_PURCHASE = 1 * (10**8); // Minimum purchase 1 coin

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    address public constant USDT_ADDRESS = 0x55d398326f99059fF775485246999027B3197955; // BNB

    IFourRXToken fourRXToken;
    IPancakeV2Router02 public pancakeV2Router;
    address public pancakeV2Pair;

    constructor (address _fourRXToken, address _pairAddress) public {
        fourRXToken = IFourRXToken(_fourRXToken);

        // IPancakeV2Router02 _pancakeV2Router = IPancakeV2Router02(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F); // Mainnet
        IPancakeV2Router02 _pancakeV2Router = IPancakeV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); // testnet // https://twitter.com/PancakeSwap/status/1369547285160370182

        // Create a uniswap pair for fourRXToken
        pancakeV2Pair = _pairAddress;

        // set the rest of the contract variables
        pancakeV2Router = _pancakeV2Router;
    }

    function addLiquidityAndBurn(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        fourRXToken.approve(address(pancakeV2Router), tokenAmount);

        IPancakeV2Pair _token = IPancakeV2Pair(pancakeV2Pair);
        uint256 balanceBefore = _token.balanceOf(address(this));

        // add the liquidity
        pancakeV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );

        uint256 balanceAfter = _token.balanceOf(address(this));
        _token.transfer(BURN_ADDRESS, balanceAfter.sub(balanceBefore).div(2)); // burn 50%

    }

    function getUSDTFromETH(uint ethAmount) internal view returns (uint) {
        IPancakeV2Factory pcsFactory = IPancakeV2Factory(pancakeV2Router.factory());
        IPancakeV2Pair usdtETHPair = IPancakeV2Pair(pcsFactory.getPair(pancakeV2Router.WETH(), USDT_ADDRESS));

        (uint112 reserve0, uint112 reserve1,) = usdtETHPair.getReserves();

        return pancakeV2Router.getAmountOut(ethAmount, uint(reserve1), uint(reserve0));
    }

    function purchase() public payable {
        require(msg.value > 0);
        require(fourRXToken.priceValidTill() >= block.number);

        uint price = fourRXToken.latestPrice();
        uint usdtValue = getUSDTFromETH(msg.value); // convert received BNB to USDT equivalent

        uint coinAmount = usdtValue.div(price);

        require(coinAmount >= MIN_PURCHASE);
        require(fourRXToken.balanceOf(address(this)) >= coinAmount.mul(2)); // need to send 100% amount for liquidity too

        fourRXToken.transfer(msg.sender, coinAmount); // send coins to user
        addLiquidityAndBurn(coinAmount, msg.value); // add 100% liquidity to pool
    }

    function recoverTokens(address _tokenAddress, address payable recipient) onlyOwner public {
        if (_tokenAddress == address(0)) {
            recipient.transfer(address(this).balance);
        } else {
            IERC20 token = IERC20(_tokenAddress);
            token.transfer(recipient, token.balanceOf(address(this)));
        }
    }
}
