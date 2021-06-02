// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


contract FourRXToken is ERC20, ChainlinkClient, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint private constant TOTAL_SUPPLY = 200*(10**6); // 200M
    uint private constant INITIAL_SUPPLY = 100*(10**3); // 100K
    uint8 private constant DECIMAL = 8;

    uint public latestPrice;
    uint public priceValidTill;
    mapping (uint => uint) public priceSnaps;
    uint[] public snapBlocks;

    address private oracle;
    bytes32 private jobId;
    uint256 private fee;

    string private constant API_URL = "https://chart-api.4rx.finance/indexPrice4RXUrl";

    constructor(address _oracle, address _linkToken) public ERC20("BRX", "BRX") {
        require(_oracle != address(0), 'FourRXToken: Oracle cannot be 0 address');
        require(_linkToken != address(0), 'FourRXToken: LinkToken cannot be 0 address');

        _mint(msg.sender, INITIAL_SUPPLY*(10**uint(DECIMAL)));
        _setupDecimals(DECIMAL);

//        setPublicChainlinkToken();
        setChainlinkToken(_linkToken);
        oracle = _oracle; // 0x2f90A6D021db21e1B2A077c5a37B3C7E75D15b7e // kovan testnet chainlink oracle
//        jobId = "29fa9aa13bf1468788b7cc4a500a45b8"; // ETH Kovan
//        jobId = "aa40e3752a35486791690344fb0e6588"; // BSC Testnet
        jobId = "c734c40b377544f08a7324f36bda4940"; // BSC MainNet // https://market.link/jobs/5ddd8a96-8840-4b55-9163-f07674c8c004?network=56
        fee = 0.02 * 10 ** 18;
    }

    function requestPrice() public returns (bytes32 requestId) {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);

        request.add("get", API_URL);

        request.add("path", "IndexPrice4RXInUSD");

        // Multiply the result by 1000000000000000000 to remove decimals
        int timesAmount = 10**18;
        request.addInt("times", timesAmount);

        // Sends the request
        return sendChainlinkRequestTo(oracle, request, fee);
    }

    /**
     * Receive the response in the form of uint256
     */
    function fulfill(bytes32 _requestId, uint256 _price) public recordChainlinkFulfillment(_requestId) {
        latestPrice = _price;
        priceValidTill = block.number + 100; // valid till 100 blocks, 300 seconds
        priceSnaps[block.number] = _price;
        snapBlocks.push(block.number);
    }

    function mint(address to, uint256 amount) public {
        require(hasRole(MINTER_ROLE, msg.sender));
        require(totalSupply() + amount <= TOTAL_SUPPLY*(10**uint(DECIMAL)));
        _mint(to, amount);
    }
}
