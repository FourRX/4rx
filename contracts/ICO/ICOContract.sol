//SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "../PancakeSwap/IPancakeV2Factory.sol";
import "../PancakeSwap/IPancakeV2Pair.sol";
import "../PancakeSwap/IPancakeV2Router01.sol";
import "../PancakeSwap/IPancakeV2Router02.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../4RX/IFourRXToken.sol";

contract ICOContract is AccessControl {
    using SafeMath for uint;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    uint public constant MIN_PURCHASE = 0.000001 * (10**8); // Minimum purchase 1 coin

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
//    address public constant USDT_ADDRESS = 0x07de306FF27a2B630B1141956844eB1552B956B5; // Kovan, ETH Mainnet
//    address public constant USDT_ADDRESS = 0x337610d27c682E347C9cD60BD4b3b107C9d34dDd; // BSCTestnet
    address public constant USDT_ADDRESS = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; // BSCMainnet BUSD
//    address public constant USDT_ADDRESS = 0xdAC17F958D2ee523a2206206994597C13D831ec7; // ETH Mainnet USDT

//    uint public constant USDT_DECIMAL = 6;  // Kovan
    uint public constant USDT_DECIMAL = 18; // BSCTestnet, BSCMainnet
//    uint public constant USDT_DECIMAL = 6; // ETH Mainnet

    uint public localPrice;

    IFourRXToken fourRXToken;
    IPancakeV2Router02 public pancakeV2Router;
    address public pancakeV2Pair;

    constructor (address _fourRXToken, address _pairAddress) public {
        require(_fourRXToken != address(0), 'ICOContract: Token address cannot be 0');
        require(_pairAddress != address(0), 'ICOContract: Pair address cannot be 0');

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(OPERATOR_ROLE, DEFAULT_ADMIN_ROLE);
        _setupRole(OPERATOR_ROLE, msg.sender);

        fourRXToken = IFourRXToken(_fourRXToken);

//         IPancakeV2Router02 _pancakeV2Router = IPancakeV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // Mainnet
//        IPancakeV2Router02 _pancakeV2Router = IPancakeV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // kovan
//        IPancakeV2Router02 _pancakeV2Router = IPancakeV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); // BSCTestnet
        IPancakeV2Router02 _pancakeV2Router = IPancakeV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // BSCMainnet

        // Create a uniswap pair for fourRXToken
        pancakeV2Pair = _pairAddress;

        // set the rest of the contract variables
        pancakeV2Router = _pancakeV2Router;
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'ICOContract: Only admins allowed');
        _;
    }

    modifier onlyOperator() {
        require(hasRole(OPERATOR_ROLE, _msgSender()), 'ICOContract: Only operators allowed');
        _;
    }

    function addLiquidityAndBurn(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        fourRXToken.approve(address(pancakeV2Router), tokenAmount);

        IPancakeV2Pair _token = IPancakeV2Pair(pancakeV2Pair);
        uint256 balanceBefore = _token.balanceOf(address(this));

        // add the liquidity
        pancakeV2Router.addLiquidityETH{value: ethAmount}(
            address(fourRXToken),
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

        return pancakeV2Router.getAmountOut(ethAmount, uint(reserve0), uint(reserve1));
    }

    function get4rxAmountFromETH(uint ethAmount) internal view returns (uint) {
        IPancakeV2Pair tokenPair = IPancakeV2Pair(pancakeV2Pair);
        (uint112 reserve0, uint112 reserve1,) = tokenPair.getReserves();

        return pancakeV2Router.getAmountOut(ethAmount, uint(reserve1), uint(reserve0));
    }

    function getEstimated4RxAmount(uint ethAmount) public view returns (uint) {
        uint price;

        if (fourRXToken.priceValidTill() >= block.number) {
            price = fourRXToken.latestPrice().div(1e8);
        } else {
            price = localPrice;
        }

        uint usdtValue = getUSDTFromETH(ethAmount).mul(10**(18 - USDT_DECIMAL)); // convert received BNB/ETH to USDT equivalent + add 12 zeros to make sure price is matched upto decimal places

        return usdtValue.div(price);
    }

    function purchase() external payable {
        require(msg.sender == tx.origin, 'ICO: No contracts allowed');
        require(msg.value > 0, 'ICO: Purchase value should be greater then 0');

        uint coinAmount = getEstimated4RxAmount(msg.value);

        uint coinAmountForLp = get4rxAmountFromETH(msg.value);

        require(coinAmount >= MIN_PURCHASE, 'ICO: Min 1 token can be purchased');
        require(fourRXToken.balanceOf(address(this)) >= coinAmount.add(coinAmountForLp), 'ICO: Not enough tokens balance to me'); // need to send 100% amount for liquidity too

        fourRXToken.transfer(msg.sender, coinAmount); // send coins to user
        addLiquidityAndBurn(coinAmountForLp, msg.value); // add 100% liquidity to pool
    }

    function recoverTokens(address _tokenAddress, address payable recipient) onlyAdmin external {
        if (_tokenAddress == address(0)) {
            recipient.transfer(address(this).balance);
        } else {
            IERC20 token = IERC20(_tokenAddress);
            token.transfer(recipient, token.balanceOf(address(this)));
        }
    }

    function updateLocalPrice(uint _localPrice) onlyOperator public {
        localPrice = _localPrice; // update price like, price => price * 1e10
    }

    receive() external payable {}
}
