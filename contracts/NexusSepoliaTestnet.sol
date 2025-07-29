// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./NexusBasePairs.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title NexusSepoliaTestnet
 * @dev Testnet-specific contract for Sepolia deployment
 * Includes mock tokens and simplified features for testing
 */
contract NexusSepoliaTestnet is NexusBasePairs {
    
    // Sepolia testnet specific addresses
    address public constant WETH_SEPOLIA = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;
    address public constant USDC_SEPOLIA = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238; // Mock USDC
    address public constant BASE_SEPOLIA = 0x0000000000000000000000000000000000000001; // Mock BASE token
    
    // Testnet configuration
    bool public isTestnet = true;
    uint256 public testnetMultiplier = 1000; // 1000x multiplier for easier testing
    mapping(address => bool) public testnetUsers;
    mapping(address => uint256) public faucetClaims;
    
    event TestnetFaucetClaim(address indexed user, uint256 amount);
    event TestnetTradeExecuted(address indexed user, string pair, uint256 amount);
    
    constructor(address _crossMargin) NexusBasePairs(_crossMargin) {
        _initializeSepoliaPairs();
    }
    
    /**
     * @dev Initialize Sepolia-specific trading pairs
     */
    function _initializeSepoliaPairs() internal {
        // BASE/ETH (Sepolia) - Primary testnet pair
        _addTradingPair(
            "BASE/ETH(Sepolia)",
            BASE_SEPOLIA,
            WETH_SEPOLIA,
            1e15,      // 0.001 BASE min trade (lower for testing)
            100000e18, // 100K BASE max trade
            1e12,      // 0.000001 ETH tick size (tighter for testing)
            1e15,      // 0.001 BASE lot size
            5,         // 0.05% maker fee (lower for testnet)
            10,        // 0.10% taker fee
            1000000000 // $1M mock liquidity
        );
        
        // Add mock liquidity for testing
        _addMockLiquidity("BASE/ETH(Sepolia)");
    }
    
    /**
     * @dev Add mock liquidity for testing purposes
     */
    function _addMockLiquidity(string memory pair) internal {
        // Create realistic order book for testing
        uint256[] memory bidPrices = new uint256[](5);
        uint256[] memory bidQuantities = new uint256[](5);
        uint256[] memory askPrices = new uint256[](5);
        uint256[] memory askQuantities = new uint256[](5);
        
        uint256 basePrice = 8e14; // 0.0008 ETH per BASE
        uint256 tickSize = 1e12;
        
        // Generate bid levels
        for (uint256 i = 0; i < 5; i++) {
            bidPrices[i] = basePrice - (tickSize * (i + 1));
            bidQuantities[i] = (1000 + i * 500) * 1e18;
        }
        
        // Generate ask levels
        for (uint256 i = 0; i < 5; i++) {
            askPrices[i] = basePrice + (tickSize * (i + 1));
            askQuantities[i] = (1000 + i * 500) * 1e18;
        }
        
        // This would call the parent contract's addLiquidity function
        // addLiquidity(pair, bidPrices, bidQuantities, askPrices, askQuantities);
    }
    
    /**
     * @dev Testnet faucet for getting test tokens
     */
    function claimTestnetTokens() external {
        require(isTestnet, "Only available on testnet");
        require(block.timestamp > faucetClaims[msg.sender] + 86400, "Can only claim once per day");
        
        // Register as testnet user
        testnetUsers[msg.sender] = true;
        faucetClaims[msg.sender] = block.timestamp;
        
        // Mock token distribution (in a real implementation, this would mint tokens)
        uint256 baseAmount = 10000 * 1e18; // 10,000 BASE tokens
        uint256 ethAmount = 5 * 1e18;      // 5 ETH
        
        // Update user balances (mock implementation)
        userBalances[msg.sender]["BASE/ETH(Sepolia)"] += baseAmount;
        
        emit TestnetFaucetClaim(msg.sender, baseAmount);
    }
    
    /**
     * @dev Execute testnet trade with enhanced logging
     */
    function executeTestnetTrade(
        string memory pair,
        uint256 quantity,
        bool isBuy,
        uint256 maxSlippage
    ) external returns (uint256 executedQuantity, uint256 avgPrice) {
        require(isTestnet, "Only available on testnet");
        require(testnetUsers[msg.sender], "Must claim testnet tokens first");
        
        // Execute the trade using parent contract logic
        (executedQuantity, avgPrice) = executeMarketOrder(pair, quantity, isBuy, maxSlippage);
        
        emit TestnetTradeExecuted(msg.sender, pair, executedQuantity);
        
        return (executedQuantity, avgPrice);
    }
    
    /**
     * @dev Get testnet-specific market data
     */
    function getTestnetMarketData(string memory pair) external view returns (
        uint256 price,
        uint256 volume24h,
        uint256 high24h,
        uint256 low24h,
        uint256 testnetLiquidity,
        bool isActive
    ) {
        require(isTestnet, "Only available on testnet");
        
        (volume24h, high24h, low24h,,,, ) = getMarketStats(pair);
        price = tradingPairs[pair].lastPrice;
        testnetLiquidity = tradingPairs[pair].liquidityDepth * testnetMultiplier;
        isActive = tradingPairs[pair].isActive;
        
        return (price, volume24h, high24h, low24h, testnetLiquidity, isActive);
    }
    
    /**
     * @dev Simulate price movements for testing
     */
    function simulatePriceMovement(
        string memory pair,
        int256 priceChangePercent
    ) external onlyOwner {
        require(isTestnet, "Only available on testnet");
        require(priceChangePercent >= -5000 && priceChangePercent <= 5000, "Price change too extreme");
        
        TradingPair storage tradingPair = tradingPairs[pair];
        uint256 currentPrice = tradingPair.lastPrice;
        
        // Calculate new price
        int256 priceChange = int256(currentPrice) * priceChangePercent / 10000;
        uint256 newPrice = uint256(int256(currentPrice) + priceChange);
        
        // Update price
        tradingPair.lastPrice = newPrice;
        tradingPair.priceUpdateTime = block.timestamp;
        
        // Update market stats
        MarketStats storage stats = marketStats[pair];
        if (newPrice > stats.high24h) {
            stats.high24h = newPrice;
        }
        if (newPrice < stats.low24h) {
            stats.low24h = newPrice;
        }
        
        emit PriceUpdated(pair, newPrice, block.timestamp);
    }
    
    /**
     * @dev Reset testnet data for fresh testing
     */
    function resetTestnetData() external onlyOwner {
        require(isTestnet, "Only available on testnet");
        
        // Reset all trading pairs to initial state
        _initializeSepoliaPairs();
        
        // Clear user balances (in a real implementation)
        // This would reset all testnet user data
    }
    
    /**
     * @dev Get testnet user status
     */
    function getTestnetUserStatus(address user) external view returns (
        bool isRegistered,
        uint256 lastFaucetClaim,
        uint256 nextClaimTime,
        uint256 baseBalance,
        uint256 ethBalance
    ) {
        require(isTestnet, "Only available on testnet");
        
        isRegistered = testnetUsers[user];
        lastFaucetClaim = faucetClaims[user];
        nextClaimTime = lastFaucetClaim + 86400;
        baseBalance = userBalances[user]["BASE/ETH(Sepolia)"];
        ethBalance = 0; // Mock ETH balance
        
        return (isRegistered, lastFaucetClaim, nextClaimTime, baseBalance, ethBalance);
    }
    
    /**
     * @dev Enable/disable testnet mode
     */
    function setTestnetMode(bool _isTestnet) external onlyOwner {
        isTestnet = _isTestnet;
    }
    
    /**
     * @dev Update testnet multiplier for easier testing
     */
    function setTestnetMultiplier(uint256 _multiplier) external onlyOwner {
        require(_multiplier >= 1 && _multiplier <= 10000, "Invalid multiplier");
        testnetMultiplier = _multiplier;
    }
    
    /**
     * @dev Get all testnet pairs
     */
    function getTestnetPairs() external view returns (string[] memory pairs) {
        require(isTestnet, "Only available on testnet");
        
        // Return testnet-specific pairs
        pairs = new string[](1);
        pairs[0] = "BASE/ETH(Sepolia)";
        
        return pairs;
    }
    
    /**
     * @dev Emergency functions for testnet
     */
    function emergencyMintTestTokens(address user, uint256 amount) external onlyOwner {
        require(isTestnet, "Only available on testnet");
        userBalances[user]["BASE/ETH(Sepolia)"] += amount;
    }
    
    function emergencySetPrice(string memory pair, uint256 newPrice) external onlyOwner {
        require(isTestnet, "Only available on testnet");
        tradingPairs[pair].lastPrice = newPrice;
        tradingPairs[pair].priceUpdateTime = block.timestamp;
        emit PriceUpdated(pair, newPrice, block.timestamp);
    }
}

/**
 * @title MockBASEToken
 * @dev Mock BASE token for Sepolia testnet
 */
contract MockBASEToken is ERC20 {
    address public minter;
    bool public isTestnet = true;
    
    constructor() ERC20("Mock BASE Token", "BASE") {
        minter = msg.sender;
        _mint(msg.sender, 1000000000 * 1e18); // 1B tokens for testing
    }
    
    function mint(address to, uint256 amount) external {
        require(msg.sender == minter, "Only minter");
        require(isTestnet, "Only on testnet");
        _mint(to, amount);
    }
    
    function faucet() external {
        require(isTestnet, "Only on testnet");
        require(balanceOf(msg.sender) < 100000 * 1e18, "Already has enough tokens");
        _mint(msg.sender, 10000 * 1e18); // 10K tokens per claim
    }
}
