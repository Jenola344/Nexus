// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./NexusCrossMargin.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title NexusBasePairs
 * @dev Specialized trading pairs for Base blockchain ecosystem
 * Supports native Base tokens with optimized pricing and liquidity
 */
contract NexusBasePairs is ReentrancyGuard, Ownable {
    
    // Base blockchain token addresses
    address public constant WETH = 0x4200000000000000000000000000000000000006; // Wrapped ETH on Base
    address public constant USDbC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913; // Coinbase-bridged USDC
    address public constant cbETH = 0x2Ae3F1Ec7F1F5012CFEab0185bfc7aa3cf0DEc22; // Coinbase Wrapped ETH
    address public constant DAI = 0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb; // DAI on Base
    address public constant AERO = 0x940181a94A35A4569E4529A3CDfB74e38FD98631; // Aerodrome token
    address public constant BASE = 0x0000000000000000000000000000000000000000; // Hypothetical BASE token

    // Sepolia testnet addresses
    address public constant WETH_SEPOLIA = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14; // Wrapped ETH on Sepolia
    address public constant BASE_SEPOLIA = 0x0000000000000000000000000000000000000001; // Hypothetical BASE token on Sepolia

    struct TradingPair {
        address baseToken;
        address quoteToken;
        string symbol;
        uint256 minTradeSize;
        uint256 maxTradeSize;
        uint256 tickSize;           // Minimum price increment
        uint256 lotSize;            // Minimum quantity increment
        uint256 makerFee;           // Fee for market makers (basis points)
        uint256 takerFee;           // Fee for market takers (basis points)
        uint256 liquidityDepth;     // Available liquidity
        bool isActive;
        uint256 lastPrice;
        uint256 priceUpdateTime;
    }

    struct OrderBookLevel {
        uint256 price;
        uint256 quantity;
        uint256 orderCount;
    }

    struct MarketStats {
        uint256 volume24h;
        uint256 high24h;
        uint256 low24h;
        uint256 change24h;
        uint256 changePercent24h;
        uint256 lastTradeTime;
        uint256 openInterest;
    }

    mapping(string => TradingPair) public tradingPairs;
    mapping(string => MarketStats) public marketStats;
    mapping(string => OrderBookLevel[]) public bids;
    mapping(string => OrderBookLevel[]) public asks;
    mapping(address => mapping(string => uint256)) public userBalances;
    
    string[] public activePairs;
    NexusCrossMargin public crossMargin;
    
    // Events
    event PairAdded(string indexed symbol, address baseToken, address quoteToken);
    event TradeExecuted(
        string indexed pair,
        address indexed trader,
        uint256 price,
        uint256 quantity,
        bool isBuy,
        uint256 fee
    );
    event LiquidityAdded(string indexed pair, uint256 bidLiquidity, uint256 askLiquidity);
    event PriceUpdated(string indexed pair, uint256 newPrice, uint256 timestamp);

    constructor(address _crossMargin) {
        crossMargin = NexusCrossMargin(_crossMargin);
        _initializeBasePairs();
    }

    /**
     * @dev Initialize Base blockchain trading pairs
     */
    function _initializeBasePairs() internal {
        // ETH/USDbC - Primary ETH trading pair
        _addTradingPair(
            "ETH/USDbC",
            WETH,
            USDbC,
            1e15,      // 0.001 ETH min trade
            1000e18,   // 1000 ETH max trade
            1e14,      // $0.0001 tick size
            1e15,      // 0.001 ETH lot size
            5,         // 0.05% maker fee
            10,        // 0.10% taker fee
            2500000000 // $2.5M initial liquidity
        );

        // cbETH/ETH - Coinbase wrapped ETH arbitrage pair
        _addTradingPair(
            "cbETH/ETH",
            cbETH,
            WETH,
            1e15,      // 0.001 cbETH min trade
            500e18,    // 500 cbETH max trade
            1e12,      // 0.000001 ETH tick size (tight spread)
            1e15,      // 0.001 cbETH lot size
            2,         // 0.02% maker fee (low for arbitrage)
            5,         // 0.05% taker fee
            1000000000 // $1M initial liquidity
        );

        // DAI/USDbC - Stablecoin pair
        _addTradingPair(
            "DAI/USDbC",
            DAI,
            USDbC,
            1e18,      // 1 DAI min trade
            1000000e18, // 1M DAI max trade
            1e14,      // $0.0001 tick size
            1e18,      // 1 DAI lot size
            1,         // 0.01% maker fee (tight for stables)
            3,         // 0.03% taker fee
            5000000000 // $5M initial liquidity
        );

        // AERO/ETH - Aerodrome governance token
        _addTradingPair(
            "AERO/ETH",
            AERO,
            WETH,
            1e18,      // 1 AERO min trade
            100000e18, // 100K AERO max trade
            1e12,      // 0.000001 ETH tick size
            1e18,      // 1 AERO lot size
            10,        // 0.10% maker fee
            20,        // 0.20% taker fee
            500000000  // $500K initial liquidity
        );

        // BASE/ETH - Hypothetical Base ecosystem token
        _addTradingPair(
            "BASE/ETH",
            BASE,
            WETH,
            1e18,      // 1 BASE min trade
            1000000e18, // 1M BASE max trade
            1e13,      // 0.00001 ETH tick size
            1e18,      // 1 BASE lot size
            15,        // 0.15% maker fee
            25,        // 0.25% taker fee
            1000000000 // $1M initial liquidity
        );

        // BASE/ETH (Sepolia) - Testnet trading pair
        _addTradingPair(
            "BASE/ETH(Sepolia)",
            BASE_SEPOLIA,
            WETH_SEPOLIA,
            1e18,      // 1 BASE min trade
            1000000e18, // 1M BASE max trade
            1e13,      // 0.00001 ETH tick size
            1e18,      // 1 BASE lot size
            10,        // 0.10% maker fee (lower for testnet)
            15,        // 0.15% taker fee
            500000000  // $500K initial liquidity
        );
    }

    /**
     * @dev Add a new trading pair
     */
    function _addTradingPair(
        string memory symbol,
        address baseToken,
        address quoteToken,
        uint256 minTradeSize,
        uint256 maxTradeSize,
        uint256 tickSize,
        uint256 lotSize,
        uint256 makerFee,
        uint256 takerFee,
        uint256 liquidityDepth
    ) internal {
        tradingPairs[symbol] = TradingPair({
            baseToken: baseToken,
            quoteToken: quoteToken,
            symbol: symbol,
            minTradeSize: minTradeSize,
            maxTradeSize: maxTradeSize,
            tickSize: tickSize,
            lotSize: lotSize,
            makerFee: makerFee,
            takerFee: takerFee,
            liquidityDepth: liquidityDepth,
            isActive: true,
            lastPrice: _getInitialPrice(symbol),
            priceUpdateTime: block.timestamp
        });

        activePairs.push(symbol);
        _initializeOrderBook(symbol);
        _initializeMarketStats(symbol);

        emit PairAdded(symbol, baseToken, quoteToken);
    }

    /**
     * @dev Get initial price for trading pair
     */
    function _getInitialPrice(string memory symbol) internal pure returns (uint256) {
        bytes32 symbolHash = keccak256(bytes(symbol));
        
        if (symbolHash == keccak256(bytes("ETH/USDbC"))) {
            return 2500e6; // $2500 USDC per ETH
        } else if (symbolHash == keccak256(bytes("cbETH/ETH"))) {
            return 1e18; // 1:1 ratio (with small premium)
        } else if (symbolHash == keccak256(bytes("DAI/USDbC"))) {
            return 1e6; // $1 USDC per DAI
        } else if (symbolHash == keccak256(bytes("AERO/ETH"))) {
            return 5e14; // 0.0005 ETH per AERO
        } else if (symbolHash == keccak256(bytes("BASE/ETH"))) {
            return 1e15; // 0.001 ETH per BASE
        } else if (symbolHash == keccak256(bytes("BASE/ETH(Sepolia)"))) {
            return 8e14; // 0.0008 ETH per BASE (slightly different from mainnet)
        }
        
        return 1e18; // Default 1:1 ratio
    }

    /**
     * @dev Initialize order book with mock liquidity
     */
    function _initializeOrderBook(string memory symbol) internal {
        uint256 basePrice = tradingPairs[symbol].lastPrice;
        uint256 tickSize = tradingPairs[symbol].tickSize;
        
        // Create 10 bid levels
        for (uint256 i = 1; i <= 10; i++) {
            uint256 bidPrice = basePrice - (tickSize * i);
            uint256 bidQuantity = (1000 + i * 100) * 1e18; // Increasing quantity at lower prices
            
            bids[symbol].push(OrderBookLevel({
                price: bidPrice,
                quantity: bidQuantity,
                orderCount: i
            }));
        }
        
        // Create 10 ask levels
        for (uint256 i = 1; i <= 10; i++) {
            uint256 askPrice = basePrice + (tickSize * i);
            uint256 askQuantity = (1000 + i * 100) * 1e18; // Increasing quantity at higher prices
            
            asks[symbol].push(OrderBookLevel({
                price: askPrice,
                quantity: askQuantity,
                orderCount: i
            }));
        }
    }

    /**
     * @dev Initialize market statistics
     */
    function _initializeMarketStats(string memory symbol) internal {
        uint256 basePrice = tradingPairs[symbol].lastPrice;
        
        marketStats[symbol] = MarketStats({
            volume24h: 1000000e18, // $1M initial volume
            high24h: basePrice * 105 / 100, // +5%
            low24h: basePrice * 95 / 100,   // -5%
            change24h: basePrice * 2 / 100,  // +2%
            changePercent24h: 200, // +2.00%
            lastTradeTime: block.timestamp,
            openInterest: 500000e18 // $500K open interest
        });
    }

    /**
     * @dev Execute market order
     */
    function executeMarketOrder(
        string memory pair,
        uint256 quantity,
        bool isBuy,
        uint256 maxSlippage
    ) external nonReentrant returns (uint256 executedQuantity, uint256 avgPrice) {
        TradingPair storage tradingPair = tradingPairs[pair];
        require(tradingPair.isActive, "Pair not active");
        require(quantity >= tradingPair.minTradeSize, "Below minimum trade size");
        require(quantity <= tradingPair.maxTradeSize, "Above maximum trade size");

        // Check cross-margin requirements
        uint256 requiredMargin = calculateRequiredMargin(pair, quantity, isBuy);
        uint256 availableMargin = crossMargin.getAvailableMargin(msg.sender);
        require(availableMargin >= requiredMargin, "Insufficient margin");

        // Execute against order book
        (executedQuantity, avgPrice) = _executeAgainstOrderBook(pair, quantity, isBuy, maxSlippage);
        
        // Calculate fees
        uint256 fee = executedQuantity * avgPrice * tradingPair.takerFee / 10000 / 1e18;
        
        // Update balances
        _updateUserBalances(msg.sender, pair, executedQuantity, avgPrice, isBuy, fee);
        
        // Update market stats
        _updateMarketStats(pair, executedQuantity, avgPrice);
        
        emit TradeExecuted(pair, msg.sender, avgPrice, executedQuantity, isBuy, fee);
    }

    /**
     * @dev Place limit order
     */
    function placeLimitOrder(
        string memory pair,
        uint256 quantity,
        uint256 price,
        bool isBuy
    ) external nonReentrant returns (uint256 orderId) {
        TradingPair storage tradingPair = tradingPairs[pair];
        require(tradingPair.isActive, "Pair not active");
        require(quantity >= tradingPair.minTradeSize, "Below minimum trade size");
        require(price % tradingPair.tickSize == 0, "Invalid tick size");

        // Check if order can be filled immediately
        uint256 bestOppositePrice = isBuy ? _getBestAsk(pair) : _getBestBid(pair);
        
        if ((isBuy && price >= bestOppositePrice) || (!isBuy && price <= bestOppositePrice)) {
            // Execute as market order
            (uint256 executedQuantity, uint256 avgPrice) = _executeAgainstOrderBook(pair, quantity, isBuy, 500); // 5% max slippage
            
            uint256 fee = executedQuantity * avgPrice * tradingPair.takerFee / 10000 / 1e18;
            _updateUserBalances(msg.sender, pair, executedQuantity, avgPrice, isBuy, fee);
            _updateMarketStats(pair, executedQuantity, avgPrice);
            
            emit TradeExecuted(pair, msg.sender, avgPrice, executedQuantity, isBuy, fee);
            return 0; // Immediate execution
        }
        
        // Add to order book
        orderId = _addToOrderBook(pair, quantity, price, isBuy);
        return orderId;
    }

    /**
     * @dev Execute order against order book
     */
    function _executeAgainstOrderBook(
        string memory pair,
        uint256 quantity,
        bool isBuy,
        uint256 maxSlippage
    ) internal returns (uint256 executedQuantity, uint256 avgPrice) {
        OrderBookLevel[] storage levels = isBuy ? asks[pair] : bids[pair];
        
        uint256 remainingQuantity = quantity;
        uint256 totalValue = 0;
        uint256 totalQuantity = 0;
        
        for (uint256 i = 0; i < levels.length && remainingQuantity > 0; i++) {
            OrderBookLevel storage level = levels[i];
            
            if (level.quantity == 0) continue;
            
            uint256 fillQuantity = remainingQuantity > level.quantity ? level.quantity : remainingQuantity;
            uint256 fillValue = fillQuantity * level.price / 1e18;
            
            // Check slippage
            uint256 currentPrice = tradingPairs[pair].lastPrice;
            uint256 slippage = isBuy ? 
                (level.price > currentPrice ? (level.price - currentPrice) * 10000 / currentPrice : 0) :
                (currentPrice > level.price ? (currentPrice - level.price) * 10000 / currentPrice : 0);
            
            require(slippage <= maxSlippage, "Slippage too high");
            
            totalValue += fillValue;
            totalQuantity += fillQuantity;
            remainingQuantity -= fillQuantity;
            level.quantity -= fillQuantity;
            
            if (level.quantity == 0) {
                level.orderCount = 0;
            }
        }
        
        require(totalQuantity > 0, "No liquidity available");
        
        executedQuantity = totalQuantity;
        avgPrice = totalValue * 1e18 / totalQuantity;
        
        // Update last price
        tradingPairs[pair].lastPrice = avgPrice;
        tradingPairs[pair].priceUpdateTime = block.timestamp;
        
        emit PriceUpdated(pair, avgPrice, block.timestamp);
    }

    /**
     * @dev Calculate required margin for trade
     */
    function calculateRequiredMargin(
        string memory pair,
        uint256 quantity,
        bool isBuy
    ) public view returns (uint256) {
        TradingPair memory tradingPair = tradingPairs[pair];
        uint256 notionalValue = quantity * tradingPair.lastPrice / 1e18;
        
        // Base margin requirement (10% for spot, 5% for stablecoins)
        uint256 marginRate = 1000; // 10%
        
        bytes32 pairHash = keccak256(bytes(pair));
        if (pairHash == keccak256(bytes("DAI/USDbC"))) {
            marginRate = 500; // 5% for stablecoin pairs
        } else if (pairHash == keccak256(bytes("cbETH/ETH"))) {
            marginRate = 300; // 3% for ETH derivatives
        }
        
        return notionalValue * marginRate / 10000;
    }

    /**
     * @dev Update user balances after trade
     */
    function _updateUserBalances(
        address user,
        string memory pair,
        uint256 quantity,
        uint256 price,
        bool isBuy,
        uint256 fee
    ) internal {
        TradingPair memory tradingPair = tradingPairs[pair];
        
        if (isBuy) {
            // User receives base token, pays quote token + fee
            userBalances[user][tradingPair.symbol] += quantity;
            uint256 quoteAmount = quantity * price / 1e18;
            // In production, this would interact with actual token transfers
        } else {
            // User pays base token, receives quote token - fee
            require(userBalances[user][tradingPair.symbol] >= quantity, "Insufficient balance");
            userBalances[user][tradingPair.symbol] -= quantity;
            // In production, this would interact with actual token transfers
        }
    }

    /**
     * @dev Update market statistics
     */
    function _updateMarketStats(
        string memory pair,
        uint256 quantity,
        uint256 price
    ) internal {
        MarketStats storage stats = marketStats[pair];
        
        stats.volume24h += quantity * price / 1e18;
        stats.lastTradeTime = block.timestamp;
        
        if (price > stats.high24h) {
            stats.high24h = price;
        }
        if (price < stats.low24h) {
            stats.low24h = price;
        }
        
        // Calculate 24h change
        uint256 oldPrice = tradingPairs[pair].lastPrice;
        if (oldPrice > 0) {
            if (price > oldPrice) {
                stats.change24h = price - oldPrice;
                stats.changePercent24h = (price - oldPrice) * 10000 / oldPrice;
            } else {
                stats.change24h = oldPrice - price;
                stats.changePercent24h = (oldPrice - price) * 10000 / oldPrice;
            }
        }
    }

    /**
     * @dev Add order to order book
     */
    function _addToOrderBook(
        string memory pair,
        uint256 quantity,
        uint256 price,
        bool isBuy
    ) internal returns (uint256 orderId) {
        OrderBookLevel[] storage levels = isBuy ? bids[pair] : asks[pair];
        
        // Find insertion point to maintain price ordering
        bool inserted = false;
        for (uint256 i = 0; i < levels.length; i++) {
            if ((isBuy && levels[i].price < price) || (!isBuy && levels[i].price > price)) {
                // Insert new level
                levels.push(); // Add empty element at end
                
                // Shift elements
                for (uint256 j = levels.length - 1; j > i; j--) {
                    levels[j] = levels[j - 1];
                }
                
                // Insert new level
                levels[i] = OrderBookLevel({
                    price: price,
                    quantity: quantity,
                    orderCount: 1
                });
                
                inserted = true;
                break;
            } else if (levels[i].price == price) {
                // Add to existing level
                levels[i].quantity += quantity;
                levels[i].orderCount += 1;
                inserted = true;
                break;
            }
        }
        
        if (!inserted) {
            // Add at end
            levels.push(OrderBookLevel({
                price: price,
                quantity: quantity,
                orderCount: 1
            }));
        }
        
        return levels.length; // Return order ID
    }

    /**
     * @dev Get best bid price
     */
    function _getBestBid(string memory pair) internal view returns (uint256) {
        OrderBookLevel[] storage bidLevels = bids[pair];
        if (bidLevels.length == 0) return 0;
        
        uint256 bestPrice = 0;
        for (uint256 i = 0; i < bidLevels.length; i++) {
            if (bidLevels[i].quantity > 0 && bidLevels[i].price > bestPrice) {
                bestPrice = bidLevels[i].price;
            }
        }
        return bestPrice;
    }

    /**
     * @dev Get best ask price
     */
    function _getBestAsk(string memory pair) internal view returns (uint256) {
        OrderBookLevel[] storage askLevels = asks[pair];
        if (askLevels.length == 0) return type(uint256).max;
        
        uint256 bestPrice = type(uint256).max;
        for (uint256 i = 0; i < askLevels.length; i++) {
            if (askLevels[i].quantity > 0 && askLevels[i].price < bestPrice) {
                bestPrice = askLevels[i].price;
            }
        }
        return bestPrice;
    }

    /**
     * @dev Get trading pair details
     */
    function getTradingPair(string memory pair) external view returns (
        address baseToken,
        address quoteToken,
        uint256 minTradeSize,
        uint256 maxTradeSize,
        uint256 tickSize,
        uint256 makerFee,
        uint256 takerFee,
        uint256 lastPrice,
        bool isActive
    ) {
        TradingPair memory tradingPair = tradingPairs[pair];
        return (
            tradingPair.baseToken,
            tradingPair.quoteToken,
            tradingPair.minTradeSize,
            tradingPair.maxTradeSize,
            tradingPair.tickSize,
            tradingPair.makerFee,
            tradingPair.takerFee,
            tradingPair.lastPrice,
            tradingPair.isActive
        );
    }

    /**
     * @dev Get market statistics
     */
    function getMarketStats(string memory pair) external view returns (
        uint256 volume24h,
        uint256 high24h,
        uint256 low24h,
        uint256 change24h,
        uint256 changePercent24h,
        uint256 lastPrice,
        uint256 openInterest
    ) {
        MarketStats memory stats = marketStats[pair];
        return (
            stats.volume24h,
            stats.high24h,
            stats.low24h,
            stats.change24h,
            stats.changePercent24h,
            tradingPairs[pair].lastPrice,
            stats.openInterest
        );
    }

    /**
     * @dev Get order book levels
     */
    function getOrderBook(string memory pair, uint256 depth) external view returns (
        uint256[] memory bidPrices,
        uint256[] memory bidQuantities,
        uint256[] memory askPrices,
        uint256[] memory askQuantities
    ) {
        OrderBookLevel[] storage bidLevels = bids[pair];
        OrderBookLevel[] storage askLevels = asks[pair];
        
        uint256 bidCount = bidLevels.length > depth ? depth : bidLevels.length;
        uint256 askCount = askLevels.length > depth ? depth : askLevels.length;
        
        bidPrices = new uint256[](bidCount);
        bidQuantities = new uint256[](bidCount);
        askPrices = new uint256[](askCount);
        askQuantities = new uint256[](askCount);
        
        // Get top bids (highest prices first)
        uint256 bidIndex = 0;
        for (uint256 i = 0; i < bidLevels.length && bidIndex < depth; i++) {
            if (bidLevels[i].quantity > 0) {
                bidPrices[bidIndex] = bidLevels[i].price;
                bidQuantities[bidIndex] = bidLevels[i].quantity;
                bidIndex++;
            }
        }
        
        // Get top asks (lowest prices first)
        uint256 askIndex = 0;
        for (uint256 i = 0; i < askLevels.length && askIndex < depth; i++) {
            if (askLevels[i].quantity > 0) {
                askPrices[askIndex] = askLevels[i].price;
                askQuantities[askIndex] = askLevels[i].quantity;
                askIndex++;
            }
        }
    }

    /**
     * @dev Get all active trading pairs
     */
    function getActivePairs() external view returns (string[] memory) {
        return activePairs;
    }

    /**
     * @dev Get user balance for a trading pair
     */
    function getUserBalance(address user, string memory pair) external view returns (uint256) {
        return userBalances[user][pair];
    }

    /**
     * @dev Emergency pause trading pair
     */
    function pauseTradingPair(string memory pair) external onlyOwner {
        tradingPairs[pair].isActive = false;
    }

    /**
     * @dev Resume trading pair
     */
    function resumeTradingPair(string memory pair) external onlyOwner {
        tradingPairs[pair].isActive = true;
    }

    /**
     * @dev Update trading fees
     */
    function updateTradingFees(
        string memory pair,
        uint256 makerFee,
        uint256 takerFee
    ) external onlyOwner {
        require(makerFee <= 100 && takerFee <= 100, "Fees too high"); // Max 1%
        tradingPairs[pair].makerFee = makerFee;
        tradingPairs[pair].takerFee = takerFee;
    }

    /**
     * @dev Add liquidity to order book (for market making)
     */
    function addLiquidity(
        string memory pair,
        uint256[] memory bidPrices,
        uint256[] memory bidQuantities,
        uint256[] memory askPrices,
        uint256[] memory askQuantities
    ) external onlyOwner {
        require(bidPrices.length == bidQuantities.length, "Bid arrays length mismatch");
        require(askPrices.length == askQuantities.length, "Ask arrays length mismatch");
        
        // Add bid liquidity
        for (uint256 i = 0; i < bidPrices.length; i++) {
            _addToOrderBook(pair, bidQuantities[i], bidPrices[i], true);
        }
        
        // Add ask liquidity
        for (uint256 i = 0; i < askPrices.length; i++) {
            _addToOrderBook(pair, askQuantities[i], askPrices[i], false);
        }
        
        uint256 totalBidLiquidity = 0;
        uint256 totalAskLiquidity = 0;
        
        for (uint256 i = 0; i < bidQuantities.length; i++) {
            totalBidLiquidity += bidQuantities[i] * bidPrices[i] / 1e18;
        }
        
        for (uint256 i = 0; i < askQuantities.length; i++) {
            totalAskLiquidity += askQuantities[i] * askPrices[i] / 1e18;
        }
        
        emit LiquidityAdded(pair, totalBidLiquidity, totalAskLiquidity);
    }
}
