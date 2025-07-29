// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title NexusAIRiskOracle
 * @dev AI-powered risk assessment and prediction oracle
 * Provides real-time risk metrics and trading signals
 */
contract NexusAIRiskOracle is Ownable, ReentrancyGuard {
    
    struct RiskMetrics {
        uint256 portfolioVaR;        // Value at Risk (95% confidence)
        uint256 expectedShortfall;   // Expected loss beyond VaR
        uint256 sharpeRatio;         // Risk-adjusted return ratio
        uint256 maxDrawdown;         // Maximum historical drawdown
        uint256 correlationRisk;     // Portfolio correlation score
        uint256 volatilityForecast;  // Predicted volatility
        uint256 liquidityRisk;       // Market liquidity assessment
        uint256 lastUpdate;
    }

    struct AISignal {
        address asset;
        int256 signal;               // -100 to +100 (bearish to bullish)
        uint256 confidence;          // 0 to 100 (confidence level)
        uint256 timeHorizon;         // Signal validity period
        string reasoning;            // AI reasoning (IPFS hash)
        uint256 timestamp;
        bool isActive;
    }

    struct MarketRegime {
        uint256 volatilityRegime;    // 1=Low, 2=Medium, 3=High, 4=Extreme
        uint256 trendStrength;       // 0-100 trend strength
        uint256 marketStress;        // 0-100 stress indicator
        uint256 liquidityCondition;  // 0-100 liquidity score
        uint256 correlationBreakdown; // Boolean for correlation breakdown
        uint256 lastUpdate;
    }

    mapping(address => RiskMetrics) public portfolioRisk;
    mapping(address => AISignal[]) public aiSignals;
    mapping(address => MarketRegime) public marketRegimes;
    mapping(address => mapping(address => uint256)) public assetCorrelations;
    
    address[] public monitoredAssets;
    address[] public monitoredPortfolios;
    
    // AI model parameters
    uint256 public modelVersion = 1;
    uint256 public confidenceThreshold = 70; // Minimum confidence for signals
    uint256 public updateFrequency = 300; // 5 minutes
    
    // Risk thresholds
    uint256 public maxVaRThreshold = 10000; // 10% max VaR
    uint256 public liquidationVaRThreshold = 15000; // 15% liquidation VaR
    uint256 public correlationThreshold = 8000; // 80% correlation warning
    
    event RiskMetricsUpdated(address indexed portfolio, uint256 vaR, uint256 sharpeRatio);
    event AISignalGenerated(address indexed asset, int256 signal, uint256 confidence);
    event RiskAlertTriggered(address indexed portfolio, string alertType, uint256 severity);
    event MarketRegimeChanged(address indexed asset, uint256 newRegime);
    event CorrelationBreakdown(address indexed asset1, address indexed asset2, uint256 newCorrelation);

    modifier onlyAuthorizedUpdater() {
        // In production, this would check for authorized AI nodes
        require(msg.sender == owner(), "Not authorized");
        _;
    }

    constructor() {}

    /**
     * @dev Update portfolio risk metrics from AI analysis
     */
    function updatePortfolioRisk(
        address portfolio,
        uint256 vaR,
        uint256 expectedShortfall,
        uint256 sharpeRatio,
        uint256 maxDrawdown,
        uint256 correlationRisk,
        uint256 volatilityForecast,
        uint256 liquidityRisk
    ) external onlyAuthorizedUpdater {
        
        RiskMetrics storage metrics = portfolioRisk[portfolio];
        
        // Validate inputs
        require(vaR <= 50000, "VaR too high"); // Max 50%
        require(sharpeRatio <= 10000, "Sharpe ratio too high"); // Max 10.0
        require(maxDrawdown <= 100000, "Max drawdown invalid"); // Max 100%
        
        metrics.portfolioVaR = vaR;
        metrics.expectedShortfall = expectedShortfall;
        metrics.sharpeRatio = sharpeRatio;
        metrics.maxDrawdown = maxDrawdown;
        metrics.correlationRisk = correlationRisk;
        metrics.volatilityForecast = volatilityForecast;
        metrics.liquidityRisk = liquidityRisk;
        metrics.lastUpdate = block.timestamp;

        // Check for risk alerts
        checkRiskAlerts(portfolio, metrics);

        emit RiskMetricsUpdated(portfolio, vaR, sharpeRatio);
    }

    /**
     * @dev Generate AI trading signal for asset
     */
    function generateAISignal(
        address asset,
        int256 signal,
        uint256 confidence,
        uint256 timeHorizon,
        string memory reasoning
    ) external onlyAuthorizedUpdater {
        require(signal >= -100 && signal <= 100, "Invalid signal range");
        require(confidence <= 100, "Invalid confidence");
        require(confidence >= confidenceThreshold, "Confidence too low");

        AISignal memory newSignal = AISignal({
            asset: asset,
            signal: signal,
            confidence: confidence,
            timeHorizon: timeHorizon,
            reasoning: reasoning,
            timestamp: block.timestamp,
            isActive: true
        });

        aiSignals[asset].push(newSignal);

        // Deactivate old signals
        if (aiSignals[asset].length > 10) {
            aiSignals[asset][aiSignals[asset].length - 11].isActive = false;
        }

        emit AISignalGenerated(asset, signal, confidence);
    }

    /**
     * @dev Update market regime classification
     */
    function updateMarketRegime(
        address asset,
        uint256 volatilityRegime,
        uint256 trendStrength,
        uint256 marketStress,
        uint256 liquidityCondition,
        uint256 correlationBreakdown
    ) external onlyAuthorizedUpdater {
        require(volatilityRegime >= 1 && volatilityRegime <= 4, "Invalid volatility regime");
        require(trendStrength <= 100, "Invalid trend strength");
        require(marketStress <= 100, "Invalid market stress");
        require(liquidityCondition <= 100, "Invalid liquidity condition");

        MarketRegime storage regime = marketRegimes[asset];
        uint256 oldRegime = regime.volatilityRegime;
        
        regime.volatilityRegime = volatilityRegime;
        regime.trendStrength = trendStrength;
        regime.marketStress = marketStress;
        regime.liquidityCondition = liquidityCondition;
        regime.correlationBreakdown = correlationBreakdown;
        regime.lastUpdate = block.timestamp;

        if (oldRegime != volatilityRegime) {
            emit MarketRegimeChanged(asset, volatilityRegime);
        }
    }

    /**
     * @dev Update asset correlation matrix
     */
    function updateCorrelations(
        address[] memory assets,
        uint256[] memory correlations
    ) external onlyAuthorizedUpdater {
        require(assets.length == correlations.length, "Array length mismatch");
        
        for (uint256 i = 0; i < assets.length; i++) {
            for (uint256 j = i + 1; j < assets.length; j++) {
                uint256 correlation = correlations[i * assets.length + j];
                require(correlation <= 10000, "Invalid correlation"); // Max 100%
                
                uint256 oldCorrelation = assetCorrelations[assets[i]][assets[j]];
                assetCorrelations[assets[i]][assets[j]] = correlation;
                assetCorrelations[assets[j]][assets[i]] = correlation;

                // Check for correlation breakdown
                if (oldCorrelation > 0 && 
                    (oldCorrelation > correlation + 2000 || correlation > oldCorrelation + 2000)) {
                    emit CorrelationBreakdown(assets[i], assets[j], correlation);
                }
            }
        }
    }

    /**
     * @dev Check and trigger risk alerts
     */
    function checkRiskAlerts(address portfolio, RiskMetrics memory metrics) internal {
        // VaR threshold alert
        if (metrics.portfolioVaR > maxVaRThreshold) {
            emit RiskAlertTriggered(portfolio, "HIGH_VAR", metrics.portfolioVaR);
        }

        // Liquidation risk alert
        if (metrics.portfolioVaR > liquidationVaRThreshold) {
            emit RiskAlertTriggered(portfolio, "LIQUIDATION_RISK", metrics.portfolioVaR);
        }

        // High correlation alert
        if (metrics.correlationRisk > correlationThreshold) {
            emit RiskAlertTriggered(portfolio, "HIGH_CORRELATION", metrics.correlationRisk);
        }

        // Low liquidity alert
        if (metrics.liquidityRisk > 8000) { // 80% liquidity risk
            emit RiskAlertTriggered(portfolio, "LOW_LIQUIDITY", metrics.liquidityRisk);
        }
    }

    /**
     * @dev Get latest AI signal for asset
     */
    function getLatestSignal(address asset) external view returns (
        int256 signal,
        uint256 confidence,
        uint256 timeHorizon,
        string memory reasoning,
        uint256 timestamp
    ) {
        AISignal[] memory signals = aiSignals[asset];
        require(signals.length > 0, "No signals available");

        for (uint256 i = signals.length; i > 0; i--) {
            if (signals[i-1].isActive && 
                block.timestamp <= signals[i-1].timestamp + signals[i-1].timeHorizon) {
                return (
                    signals[i-1].signal,
                    signals[i-1].confidence,
                    signals[i-1].timeHorizon,
                    signals[i-1].reasoning,
                    signals[i-1].timestamp
                );
            }
        }

        revert("No active signals");
    }

    /**
     * @dev Get portfolio risk assessment
     */
    function getPortfolioRisk(address portfolio) external view returns (
        uint256 vaR,
        uint256 expectedShortfall,
        uint256 sharpeRatio,
        uint256 maxDrawdown,
        uint256 correlationRisk,
        uint256 volatilityForecast,
        uint256 liquidityRisk,
        string memory riskLevel
    ) {
        RiskMetrics memory metrics = portfolioRisk[portfolio];
        
        string memory level = "LOW";
        if (metrics.portfolioVaR > maxVaRThreshold) {
            level = "HIGH";
        } else if (metrics.portfolioVaR > maxVaRThreshold / 2) {
            level = "MEDIUM";
        }

        return (
            metrics.portfolioVaR,
            metrics.expectedShortfall,
            metrics.sharpeRatio,
            metrics.maxDrawdown,
            metrics.correlationRisk,
            metrics.volatilityForecast,
            metrics.liquidityRisk,
            level
        );
    }

    /**
     * @dev Get market regime for asset
     */
    function getMarketRegime(address asset) external view returns (
        string memory volatilityLevel,
        uint256 trendStrength,
        uint256 marketStress,
        uint256 liquidityCondition,
        bool correlationBreakdown
    ) {
        MarketRegime memory regime = marketRegimes[asset];
        
        string memory volLevel = "LOW";
        if (regime.volatilityRegime == 2) volLevel = "MEDIUM";
        else if (regime.volatilityRegime == 3) volLevel = "HIGH";
        else if (regime.volatilityRegime == 4) volLevel = "EXTREME";

        return (
            volLevel,
            regime.trendStrength,
            regime.marketStress,
            regime.liquidityCondition,
            regime.correlationBreakdown == 1
        );
    }

    /**
     * @dev Calculate portfolio diversification score
     */
    function calculateDiversificationScore(
        address[] memory assets,
        uint256[] memory weights
    ) external view returns (uint256 score) {
        require(assets.length == weights.length, "Array length mismatch");
        
        uint256 totalCorrelation = 0;
        uint256 pairCount = 0;

        for (uint256 i = 0; i < assets.length; i++) {
            for (uint256 j = i + 1; j < assets.length; j++) {
                uint256 correlation = assetCorrelations[assets[i]][assets[j]];
                uint256 weightProduct = weights[i] * weights[j] / 10000;
                totalCorrelation += correlation * weightProduct / 10000;
                pairCount++;
            }
        }

        if (pairCount == 0) return 10000; // Perfect diversification
        
        uint256 avgCorrelation = totalCorrelation / pairCount;
        return 10000 - avgCorrelation; // Higher score = better diversification
    }

    /**
     * @dev Predict portfolio VaR for next period
     */
    function predictPortfolioVaR(
        address portfolio,
        uint256 timeHorizon
    ) external view returns (uint256 predictedVaR, uint256 confidence) {
        RiskMetrics memory metrics = portfolioRisk[portfolio];
        
        // Simple VaR scaling with time horizon
        uint256 scalingFactor = sqrt(timeHorizon * 10000 / 86400); // Daily to custom horizon
        predictedVaR = metrics.portfolioVaR * scalingFactor / 10000;
        
        // Confidence decreases with longer time horizons
        confidence = timeHorizon <= 86400 ? 90 : // 1 day: 90%
                    timeHorizon <= 604800 ? 75 : // 1 week: 75%
                    60; // Longer: 60%
        
        return (predictedVaR, confidence);
    }

    /**
     * @dev Emergency risk override (pause trading if extreme risk detected)
     */
    function emergencyRiskOverride(address portfolio, string memory reason) external onlyOwner {
        emit RiskAlertTriggered(portfolio, "EMERGENCY_OVERRIDE", 10000);
        // This would trigger emergency procedures in connected contracts
    }

    // Mathematical helper functions
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }

    /**
     * @dev Update AI model parameters
     */
    function updateModelParameters(
        uint256 newModelVersion,
        uint256 newConfidenceThreshold,
        uint256 newUpdateFrequency
    ) external onlyOwner {
        require(newConfidenceThreshold <= 100, "Invalid confidence threshold");
        require(newUpdateFrequency >= 60, "Update frequency too high");
        
        modelVersion = newModelVersion;
        confidenceThreshold = newConfidenceThreshold;
        updateFrequency = newUpdateFrequency;
    }
}
