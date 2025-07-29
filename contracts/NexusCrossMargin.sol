// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title NexusCrossMargin
 * @dev Core cross-margining engine for NEXUS derivatives platform
 * Implements portfolio-level risk management with automated liquidations
 */
contract NexusCrossMargin is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Constants
    uint256 public constant PRECISION = 1e18;
    uint256 public constant MAX_LEVERAGE = 50; // 50x max leverage
    uint256 public constant LIQUIDATION_THRESHOLD = 8000; // 80% margin ratio
    uint256 public constant MAINTENANCE_MARGIN = 5000; // 50% maintenance margin
    uint256 public constant LIQUIDATION_PENALTY = 500; // 5% liquidation penalty

    // Structs
    struct Position {
        address asset;
        int256 size; // Positive for long, negative for short
        uint256 entryPrice;
        uint256 entryTime;
        uint256 funding; // Accumulated funding
        bool isActive;
    }

    struct Portfolio {
        uint256 collateral; // Total collateral in USD
        uint256 marginUsed; // Used margin in USD
        uint256 unrealizedPnL; // Unrealized P&L in USD
        int256 totalExposure; // Net exposure across all positions
        uint256 lastUpdateTime;
        bool isLiquidating;
    }

    struct MarketData {
        uint256 price;
        uint256 volatility;
        uint256 fundingRate;
        uint256 openInterest;
        uint256 lastUpdate;
        bool isActive;
    }

    // State variables
    mapping(address => Portfolio) public portfolios;
    mapping(address => mapping(uint256 => Position)) public positions;
    mapping(address => uint256) public positionCounts;
    mapping(address => MarketData) public markets;
    mapping(address => bool) public supportedAssets;
    mapping(address => uint256) public assetWeights; // Risk weights for different assets

    address[] public activeMarkets;
    address public priceOracle;
    address public riskOracle;
    address public liquidationEngine;
    address public feeCollector;

    uint256 public totalValueLocked;
    uint256 public totalOpenInterest;
    uint256 public protocolFee = 30; // 0.3%

    // Events
    event PositionOpened(
        address indexed trader,
        address indexed asset,
        uint256 indexed positionId,
        int256 size,
        uint256 entryPrice
    );

    event PositionClosed(
        address indexed trader,
        address indexed asset,
        uint256 indexed positionId,
        int256 pnl
    );

    event MarginDeposited(address indexed trader, uint256 amount);
    event MarginWithdrawn(address indexed trader, uint256 amount);
    event LiquidationTriggered(address indexed trader, uint256 liquidationValue);
    event CrossMarginBenefit(address indexed trader, uint256 savedMargin);

    // Modifiers
    modifier onlyActiveMarket(address asset) {
        require(supportedAssets[asset], "Market not supported");
        require(markets[asset].isActive, "Market not active");
        _;
    }

    modifier notLiquidating(address trader) {
        require(!portfolios[trader].isLiquidating, "Portfolio under liquidation");
        _;
    }

    constructor(
        address _priceOracle,
        address _riskOracle,
        address _liquidationEngine,
        address _feeCollector
    ) {
        priceOracle = _priceOracle;
        riskOracle = _riskOracle;
        liquidationEngine = _liquidationEngine;
        feeCollector = _feeCollector;
    }

    /**
     * @dev Deposit collateral for cross-margin trading
     */
    function depositMargin(uint256 amount) external nonReentrant {
        require(amount > 0, "Invalid amount");
        
        IERC20(address(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913)).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        ); // USDC on Base

        portfolios[msg.sender].collateral = portfolios[msg.sender].collateral.add(amount);
        totalValueLocked = totalValueLocked.add(amount);

        emit MarginDeposited(msg.sender, amount);
    }

    /**
     * @dev Withdraw available margin
     */
    function withdrawMargin(uint256 amount) external nonReentrant notLiquidating(msg.sender) {
        Portfolio storage portfolio = portfolios[msg.sender];
        
        uint256 availableMargin = getAvailableMargin(msg.sender);
        require(amount <= availableMargin, "Insufficient available margin");

        portfolio.collateral = portfolio.collateral.sub(amount);
        totalValueLocked = totalValueLocked.sub(amount);

        IERC20(address(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913)).safeTransfer(msg.sender, amount);

        emit MarginWithdrawn(msg.sender, amount);
    }

    /**
     * @dev Open a new position with cross-margin benefits
     */
    function openPosition(
        address asset,
        int256 size,
        uint256 maxSlippage
    ) external nonReentrant onlyActiveMarket(asset) notLiquidating(msg.sender) {
        require(size != 0, "Invalid position size");
        
        uint256 currentPrice = getCurrentPrice(asset);
        uint256 positionValue = uint256(size > 0 ? size : -size).mul(currentPrice).div(PRECISION);
        
        // Calculate required margin with cross-margin benefits
        uint256 requiredMargin = calculateRequiredMargin(msg.sender, asset, size, currentPrice);
        uint256 availableMargin = getAvailableMargin(msg.sender);
        
        require(availableMargin >= requiredMargin, "Insufficient margin");

        // Create position
        uint256 positionId = positionCounts[msg.sender];
        positions[msg.sender][positionId] = Position({
            asset: asset,
            size: size,
            entryPrice: currentPrice,
            entryTime: block.timestamp,
            funding: 0,
            isActive: true
        });

        positionCounts[msg.sender]++;

        // Update portfolio
        Portfolio storage portfolio = portfolios[msg.sender];
        portfolio.marginUsed = portfolio.marginUsed.add(requiredMargin);
        portfolio.totalExposure = portfolio.totalExposure + size;
        portfolio.lastUpdateTime = block.timestamp;

        // Update market data
        markets[asset].openInterest = markets[asset].openInterest.add(positionValue);
        totalOpenInterest = totalOpenInterest.add(positionValue);

        emit PositionOpened(msg.sender, asset, positionId, size, currentPrice);
        
        // Calculate and emit cross-margin benefit
        uint256 isolatedMargin = positionValue.mul(assetWeights[asset]).div(10000);
        if (isolatedMargin > requiredMargin) {
            emit CrossMarginBenefit(msg.sender, isolatedMargin.sub(requiredMargin));
        }
    }

    /**
     * @dev Close an existing position
     */
    function closePosition(uint256 positionId) external nonReentrant {
        Position storage position = positions[msg.sender][positionId];
        require(position.isActive, "Position not active");

        uint256 currentPrice = getCurrentPrice(position.asset);
        int256 pnl = calculatePnL(position, currentPrice);

        // Update portfolio
        Portfolio storage portfolio = portfolios[msg.sender];
        portfolio.unrealizedPnL = uint256(int256(portfolio.unrealizedPnL) + pnl);
        portfolio.totalExposure = portfolio.totalExposure - position.size;

        // Calculate and release margin
        uint256 releasedMargin = calculateRequiredMargin(
            msg.sender,
            position.asset,
            position.size,
            position.entryPrice
        );
        portfolio.marginUsed = portfolio.marginUsed.sub(releasedMargin);

        // Update market data
        uint256 positionValue = uint256(position.size > 0 ? position.size : -position.size)
            .mul(position.entryPrice).div(PRECISION);
        markets[position.asset].openInterest = markets[position.asset].openInterest.sub(positionValue);
        totalOpenInterest = totalOpenInterest.sub(positionValue);

        position.isActive = false;

        emit PositionClosed(msg.sender, position.asset, positionId, pnl);
    }

    /**
     * @dev Calculate required margin with cross-margin benefits
     */
    function calculateRequiredMargin(
        address trader,
        address asset,
        int256 size,
        uint256 price
    ) public view returns (uint256) {
        uint256 positionValue = uint256(size > 0 ? size : -size).mul(price).div(PRECISION);
        uint256 baseMargin = positionValue.mul(assetWeights[asset]).div(10000);

        // Apply cross-margin benefits
        Portfolio memory portfolio = portfolios[trader];
        if (portfolio.collateral > 0) {
            // Reduce margin requirement based on portfolio diversification
            uint256 diversificationBonus = calculateDiversificationBonus(trader, asset);
            uint256 correlationDiscount = calculateCorrelationDiscount(trader, asset);
            
            uint256 totalDiscount = diversificationBonus.add(correlationDiscount);
            if (totalDiscount > 3000) totalDiscount = 3000; // Max 30% discount
            
            baseMargin = baseMargin.mul(10000 - totalDiscount).div(10000);
        }

        return baseMargin;
    }

    /**
     * @dev Calculate portfolio-level margin ratio
     */
    function getMarginRatio(address trader) public view returns (uint256) {
        Portfolio memory portfolio = portfolios[trader];
        if (portfolio.collateral == 0) return 0;

        uint256 totalValue = portfolio.collateral;
        if (portfolio.unrealizedPnL > 0) {
            totalValue = totalValue.add(portfolio.unrealizedPnL);
        } else {
            totalValue = totalValue.sub(uint256(-int256(portfolio.unrealizedPnL)));
        }

        return portfolio.marginUsed.mul(10000).div(totalValue);
    }

    /**
     * @dev Get available margin for new positions
     */
    function getAvailableMargin(address trader) public view returns (uint256) {
        Portfolio memory portfolio = portfolios[trader];
        uint256 totalValue = portfolio.collateral;
        
        // Add unrealized PnL
        if (portfolio.unrealizedPnL > 0) {
            totalValue = totalValue.add(portfolio.unrealizedPnL);
        } else {
            if (uint256(-int256(portfolio.unrealizedPnL)) >= totalValue) {
                return 0;
            }
            totalValue = totalValue.sub(uint256(-int256(portfolio.unrealizedPnL)));
        }

        if (totalValue <= portfolio.marginUsed) return 0;
        return totalValue.sub(portfolio.marginUsed);
    }

    /**
     * @dev Check if portfolio is eligible for liquidation
     */
    function isLiquidationEligible(address trader) public view returns (bool) {
        uint256 marginRatio = getMarginRatio(trader);
        return marginRatio >= LIQUIDATION_THRESHOLD;
    }

    /**
     * @dev Trigger liquidation for undercollateralized portfolio
     */
    function liquidatePortfolio(address trader) external {
        require(msg.sender == liquidationEngine, "Only liquidation engine");
        require(isLiquidationEligible(trader), "Not eligible for liquidation");

        portfolios[trader].isLiquidating = true;
        
        // Calculate liquidation value
        uint256 liquidationValue = portfolios[trader].collateral
            .mul(LIQUIDATION_PENALTY).div(10000);

        emit LiquidationTriggered(trader, liquidationValue);
    }

    /**
     * @dev Calculate P&L for a position
     */
    function calculatePnL(Position memory position, uint256 currentPrice) internal pure returns (int256) {
        int256 priceDiff = int256(currentPrice) - int256(position.entryPrice);
        return (position.size * priceDiff) / int256(PRECISION);
    }

    /**
     * @dev Calculate diversification bonus for cross-margin benefits
     */
    function calculateDiversificationBonus(address trader, address asset) internal view returns (uint256) {
        // Simplified diversification calculation
        // In production, this would analyze portfolio composition
        uint256 positionCount = positionCounts[trader];
        if (positionCount >= 5) return 1000; // 10% bonus for 5+ positions
        if (positionCount >= 3) return 500;  // 5% bonus for 3+ positions
        return 0;
    }

    /**
     * @dev Calculate correlation discount based on portfolio correlation
     */
    function calculateCorrelationDiscount(address trader, address asset) internal view returns (uint256) {
        // Simplified correlation calculation
        // In production, this would use real correlation data
        return 500; // 5% discount for low correlation
    }

    /**
     * @dev Get current price from oracle
     */
    function getCurrentPrice(address asset) internal view returns (uint256) {
        // In production, this would call the price oracle
        return markets[asset].price;
    }

    /**
     * @dev Add supported market
     */
    function addMarket(
        address asset,
        uint256 initialPrice,
        uint256 weight,
        uint256 volatility
    ) external onlyOwner {
        require(!supportedAssets[asset], "Market already exists");
        
        supportedAssets[asset] = true;
        assetWeights[asset] = weight;
        markets[asset] = MarketData({
            price: initialPrice,
            volatility: volatility,
            fundingRate: 0,
            openInterest: 0,
            lastUpdate: block.timestamp,
            isActive: true
        });
        
        activeMarkets.push(asset);
    }

    /**
     * @dev Initialize Base blockchain markets
     */
    function initializeBaseMarkets() external onlyOwner {
        // ETH/USDbC - Primary trading pair
        addMarket(
            0x4200000000000000000000000000000000000006, // WETH
            2500000000, // $2500 initial price
            1000,       // 10% weight
            2000        // 20% volatility
        );
        
        // cbETH/ETH - Coinbase wrapped ETH
        addMarket(
            0x2Ae3F1Ec7F1F5012CFEab0185bfc7aa3cf0DEc22, // cbETH
            1000000000000000000, // 1.0 ETH initial price
            800,        // 8% weight
            1500        // 15% volatility
        );
        
        // DAI/USDbC - Stablecoin pair
        addMarket(
            0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb, // DAI
            1000000,    // $1.00 initial price
            500,        // 5% weight (lower risk)
            500         // 5% volatility
        );
        
        // AERO/ETH - Aerodrome token
        addMarket(
            0x940181a94A35A4569E4529A3CDfB74e38FD98631, // AERO
            500000000000000, // 0.0005 ETH initial price
            1500,       // 15% weight
            4000        // 40% volatility
        );
        
        // BASE/ETH - Hypothetical BASE token
        addMarket(
            0x0000000000000000000000000000000000000000, // BASE (placeholder)
            1000000000000000, // 0.001 ETH initial price
            2000,       // 20% weight
            5000        // 50% volatility
        );
    }

    /**
     * @dev Update market price (called by oracle)
     */
    function updatePrice(address asset, uint256 newPrice) external {
        require(msg.sender == priceOracle, "Only price oracle");
        markets[asset].price = newPrice;
        markets[asset].lastUpdate = block.timestamp;
    }

    /**
     * @dev Get portfolio summary
     */
    function getPortfolioSummary(address trader) external view returns (
        uint256 collateral,
        uint256 marginUsed,
        uint256 availableMargin,
        uint256 marginRatio,
        uint256 unrealizedPnL,
        uint256 positionCount
    ) {
        Portfolio memory portfolio = portfolios[trader];
        return (
            portfolio.collateral,
            portfolio.marginUsed,
            getAvailableMargin(trader),
            getMarginRatio(trader),
            portfolio.unrealizedPnL,
            positionCounts[trader]
        );
    }

    /**
     * @dev Emergency pause
     */
    function pause() external onlyOwner {
        // Pause all trading activities
        for (uint i = 0; i < activeMarkets.length; i++) {
            markets[activeMarkets[i]].isActive = false;
        }
    }
}
