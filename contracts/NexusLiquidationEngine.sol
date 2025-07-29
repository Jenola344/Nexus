// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./NexusCrossMargin.sol";
import "./NexusAIRiskOracle.sol";

/**
 * @title NexusLiquidationEngine
 * @dev Automated liquidation system with AI-powered risk assessment
 * Handles portfolio-level liquidations with cross-margin considerations
 */
contract NexusLiquidationEngine is ReentrancyGuard, Ownable {
    
    struct LiquidationJob {
        address trader;
        uint256 priority;           // Higher = more urgent
        uint256 estimatedGas;
        uint256 maxReward;
        uint256 deadline;
        bool isActive;
        uint256 createdAt;
    }

    struct LiquidatorInfo {
        uint256 totalLiquidations;
        uint256 successfulLiquidations;
        uint256 totalRewards;
        uint256 reputation;         // 0-10000 (0-100%)
        bool isActive;
        uint256 lastActivity;
    }

    NexusCrossMargin public crossMargin;
    NexusAIRiskOracle public riskOracle;
    
    mapping(address => LiquidationJob) public liquidationJobs;
    mapping(address => LiquidatorInfo) public liquidators;
    mapping(address => bool) public authorizedLiquidators;
    
    address[] public pendingLiquidations;
    address[] public registeredLiquidators;
    
    uint256 public baseLiquidationReward = 50; // 0.5%
    uint256 public maxLiquidationReward = 500; // 5%
    uint256 public liquidationDelay = 300; // 5 minutes grace period
    uint256 public emergencyLiquidationThreshold = 9500; // 95% margin ratio
    uint256 public minLiquidatorReputation = 5000; // 50% min reputation
    
    // Gas optimization
    uint256 public maxBatchSize = 10;
    uint256 public gasSubsidy = 50000; // Gas subsidy for liquidators
    
    event LiquidationQueued(address indexed trader, uint256 priority, uint256 deadline);
    event LiquidationExecuted(address indexed trader, address indexed liquidator, uint256 reward);
    event LiquidatorRegistered(address indexed liquidator);
    event EmergencyLiquidation(address indexed trader, uint256 marginRatio);
    event BatchLiquidationExecuted(uint256 count, uint256 totalRewards);

    modifier onlyAuthorizedLiquidator() {
        require(authorizedLiquidators[msg.sender] || msg.sender == owner(), "Not authorized liquidator");
        require(liquidators[msg.sender].reputation >= minLiquidatorReputation, "Reputation too low");
        _;
    }

    constructor(address _crossMargin, address _riskOracle) {
        crossMargin = NexusCrossMargin(_crossMargin);
        riskOracle = NexusAIRiskOracle(_riskOracle);
    }

    /**
     * @dev Register as a liquidator
     */
    function registerLiquidator() external {
        require(!authorizedLiquidators[msg.sender], "Already registered");
        
        authorizedLiquidators[msg.sender] = true;
        liquidators[msg.sender] = LiquidatorInfo({
            totalLiquidations: 0,
            successfulLiquidations: 0,
            totalRewards: 0,
            reputation: 7500, // Start with 75% reputation
            isActive: true,
            lastActivity: block.timestamp
        });
        
        registeredLiquidators.push(msg.sender);
        emit LiquidatorRegistered(msg.sender);
    }

    /**
     * @dev Queue a trader for liquidation
     */
    function queueLiquidation(address trader) external {
        require(crossMargin.isLiquidationEligible(trader), "Not eligible for liquidation");
        require(!liquidationJobs[trader].isActive, "Already queued");

        uint256 marginRatio = crossMargin.getMarginRatio(trader);
        uint256 priority = calculateLiquidationPriority(trader, marginRatio);
        uint256 estimatedReward = calculateLiquidationReward(trader, marginRatio);
        
        // Emergency liquidation for extremely high risk
        if (marginRatio >= emergencyLiquidationThreshold) {
            _executeEmergencyLiquidation(trader);
            return;
        }

        liquidationJobs[trader] = LiquidationJob({
            trader: trader,
            priority: priority,
            estimatedGas: estimateGasCost(trader),
            maxReward: estimatedReward,
            deadline: block.timestamp + liquidationDelay,
            isActive: true,
            createdAt: block.timestamp
        });

        pendingLiquidations.push(trader);
        emit LiquidationQueued(trader, priority, block.timestamp + liquidationDelay);
    }

    /**
     * @dev Execute single liquidation
     */
    function executeLiquidation(address trader) external nonReentrant onlyAuthorizedLiquidator {
        LiquidationJob storage job = liquidationJobs[trader];
        require(job.isActive, "No active liquidation job");
        require(block.timestamp >= job.deadline, "Grace period not expired");
        require(crossMargin.isLiquidationEligible(trader), "No longer eligible");

        uint256 gasStart = gasleft();
        
        // Execute liquidation through cross-margin contract
        crossMargin.liquidatePortfolio(trader);
        
        // Calculate actual reward
        uint256 marginRatio = crossMargin.getMarginRatio(trader);
        uint256 reward = calculateLiquidationReward(trader, marginRatio);
        
        // Update liquidator stats
        LiquidatorInfo storage liquidator = liquidators[msg.sender];
        liquidator.totalLiquidations++;
        liquidator.successfulLiquidations++;
        liquidator.totalRewards += reward;
        liquidator.lastActivity = block.timestamp;
        
        // Update reputation based on performance
        _updateLiquidatorReputation(msg.sender, true, gasStart - gasleft());

        // Clean up
        job.isActive = false;
        _removePendingLiquidation(trader);

        // Pay liquidator
        _payLiquidator(msg.sender, reward);

        emit LiquidationExecuted(trader, msg.sender, reward);
    }

    /**
     * @dev Execute batch liquidations for gas efficiency
     */
    function executeBatchLiquidation(
        address[] memory traders,
        uint256 maxGasUsed
    ) external nonReentrant onlyAuthorizedLiquidator {
        require(traders.length <= maxBatchSize, "Batch too large");
        
        uint256 gasStart = gasleft();
        uint256 totalRewards = 0;
        uint256 successCount = 0;

        for (uint256 i = 0; i < traders.length && gasleft() > maxGasUsed / traders.length; i++) {
            address trader = traders[i];
            LiquidationJob storage job = liquidationJobs[trader];
            
            if (job.isActive && 
                block.timestamp >= job.deadline && 
                crossMargin.isLiquidationEligible(trader)) {
                
                try crossMargin.liquidatePortfolio(trader) {
                    uint256 marginRatio = crossMargin.getMarginRatio(trader);
                    uint256 reward = calculateLiquidationReward(trader, marginRatio);
                    totalRewards += reward;
                    successCount++;
                    
                    job.isActive = false;
                    _removePendingLiquidation(trader);
                } catch {
                    // Continue with next liquidation if one fails
                    continue;
                }
            }
        }

        if (successCount > 0) {
            // Update liquidator stats
            LiquidatorInfo storage liquidator = liquidators[msg.sender];
            liquidator.totalLiquidations += successCount;
            liquidator.successfulLiquidations += successCount;
            liquidator.totalRewards += totalRewards;
            liquidator.lastActivity = block.timestamp;
            
            // Bonus reputation for batch efficiency
            _updateLiquidatorReputation(msg.sender, true, gasStart - gasleft());
            liquidator.reputation = liquidator.reputation > 9500 ? 10000 : liquidator.reputation + 50;

            _payLiquidator(msg.sender, totalRewards);
            emit BatchLiquidationExecuted(successCount, totalRewards);
        }
    }

    /**
     * @dev AI-powered liquidation monitoring
     */
    function aiMonitorLiquidations() external {
        require(msg.sender == address(riskOracle), "Only risk oracle");
        
        // Get high-risk portfolios from AI oracle
        for (uint256 i = 0; i < pendingLiquidations.length; i++) {
            address trader = pendingLiquidations[i];
            
            // Get AI risk assessment
            (uint256 vaR,,,,,, string memory riskLevel) = riskOracle.getPortfolioRisk(trader);
            
            if (keccak256(bytes(riskLevel)) == keccak256(bytes("HIGH"))) {
                LiquidationJob storage job = liquidationJobs[trader];
                if (job.isActive) {
                    // Increase priority for AI-identified high-risk positions
                    job.priority = job.priority > 8000 ? 10000 : job.priority + 2000;
                    
                    // Reduce grace period for extreme risk
                    if (vaR > 12000) { // 12% VaR
                        job.deadline = block.timestamp + liquidationDelay / 2;
                    }
                }
            }
        }
    }

    /**
     * @dev Calculate liquidation priority based on risk metrics
     */
    function calculateLiquidationPriority(
        address trader,
        uint256 marginRatio
    ) internal view returns (uint256) {
        uint256 basePriority = marginRatio > 8000 ? (marginRatio - 8000) * 50 : 0;
        
        // Get AI risk assessment
        try riskOracle.getPortfolioRisk(trader) returns (
            uint256 vaR, uint256, uint256, uint256, uint256, uint256, uint256, string memory riskLevel
        ) {
            // Increase priority based on VaR
            uint256 varBonus = vaR > 10000 ? (vaR - 10000) * 10 : 0;
            
            // Risk level bonus
            uint256 riskBonus = 0;
            if (keccak256(bytes(riskLevel)) == keccak256(bytes("HIGH"))) {
                riskBonus = 2000;
            }
            
            return basePriority + varBonus + riskBonus;
        } catch {
            return basePriority;
        }
    }

    /**
     * @dev Calculate liquidation reward
     */
    function calculateLiquidationReward(
        address trader,
        uint256 marginRatio
    ) internal view returns (uint256) {
        (uint256 collateral,,,,,) = crossMargin.getPortfolioSummary(trader);
        
        // Base reward increases with margin ratio
        uint256 rewardRate = baseLiquidationReward;
        if (marginRatio > 9000) {
            rewardRate = baseLiquidationReward * 3; // 3x for high risk
        } else if (marginRatio > 8500) {
            rewardRate = baseLiquidationReward * 2; // 2x for medium-high risk
        }
        
        uint256 reward = collateral * rewardRate / 10000;
        uint256 maxReward = collateral * maxLiquidationReward / 10000;
        
        return reward > maxReward ? maxReward : reward;
    }

    /**
     * @dev Estimate gas cost for liquidation
     */
    function estimateGasCost(address trader) internal view returns (uint256) {
        (,,,, uint256 positionCount) = crossMargin.getPortfolioSummary(trader);
        
        // Base gas + per position gas
        uint256 baseGas = 200000;
        uint256 perPositionGas = 50000;
        
        return baseGas + (positionCount * perPositionGas);
    }

    /**
     * @dev Execute emergency liquidation
     */
    function _executeEmergencyLiquidation(address trader) internal {
        uint256 marginRatio = crossMargin.getMarginRatio(trader);
        
        // Immediate liquidation without grace period
        crossMargin.liquidatePortfolio(trader);
        
        emit EmergencyLiquidation(trader, marginRatio);
    }

    /**
     * @dev Update liquidator reputation
     */
    function _updateLiquidatorReputation(
        address liquidator,
        bool successful,
        uint256 gasUsed
    ) internal {
        LiquidatorInfo storage info = liquidators[liquidator];
        
        if (successful) {
            // Increase reputation for successful liquidations
            uint256 bonus = 25; // Base bonus
            
            // Gas efficiency bonus
            if (gasUsed < info.totalLiquidations > 0 ? 
                (info.totalRewards / info.totalLiquidations) : 300000) {
                bonus += 25; // Efficient gas usage
            }
            
            info.reputation = info.reputation + bonus > 10000 ? 10000 : info.reputation + bonus;
        } else {
            // Decrease reputation for failed liquidations
            info.reputation = info.reputation > 100 ? info.reputation - 100 : 0;
        }
    }

    /**
     * @dev Pay liquidator reward
     */
    function _payLiquidator(address liquidator, uint256 reward) internal {
        // In production, this would transfer USDC or ETH
        // For now, we'll emit an event
        // IERC20(collateralToken).transfer(liquidator, reward);
    }

    /**
     * @dev Remove trader from pending liquidations
     */
    function _removePendingLiquidation(address trader) internal {
        for (uint256 i = 0; i < pendingLiquidations.length; i++) {
            if (pendingLiquidations[i] == trader) {
                pendingLiquidations[i] = pendingLiquidations[pendingLiquidations.length - 1];
                pendingLiquidations.pop();
                break;
            }
        }
    }

    /**
     * @dev Get pending liquidations sorted by priority
     */
    function getPendingLiquidations() external view returns (
        address[] memory traders,
        uint256[] memory priorities,
        uint256[] memory rewards,
        uint256[] memory deadlines
    ) {
        uint256 count = pendingLiquidations.length;
        traders = new address[](count);
        priorities = new uint256[](count);
        rewards = new uint256[](count);
        deadlines = new uint256[](count);

        for (uint256 i = 0; i < count; i++) {
            address trader = pendingLiquidations[i];
            LiquidationJob memory job = liquidationJobs[trader];
            
            traders[i] = trader;
            priorities[i] = job.priority;
            rewards[i] = job.maxReward;
            deadlines[i] = job.deadline;
        }
    }

    /**
     * @dev Get liquidator statistics
     */
    function getLiquidatorStats(address liquidator) external view returns (
        uint256 totalLiquidations,
        uint256 successRate,
        uint256 totalRewards,
        uint256 reputation,
        bool isActive
    ) {
        LiquidatorInfo memory info = liquidators[liquidator];
        uint256 successRate = info.totalLiquidations > 0 ? 
            (info.successfulLiquidations * 10000 / info.totalLiquidations) : 0;
        
        return (
            info.totalLiquidations,
            successRate,
            info.totalRewards,
            info.reputation,
            info.isActive
        );
    }

    /**
     * @dev Emergency pause liquidations
     */
    function pauseLiquidations() external onlyOwner {
        // Clear all pending liquidations
        delete pendingLiquidations;
    }

    /**
     * @dev Update liquidation parameters
     */
    function updateLiquidationParameters(
        uint256 _baseLiquidationReward,
        uint256 _maxLiquidationReward,
        uint256 _liquidationDelay,
        uint256 _emergencyThreshold
    ) external onlyOwner {
        require(_baseLiquidationReward <= _maxLiquidationReward, "Invalid reward range");
        require(_liquidationDelay >= 60, "Delay too short"); // Min 1 minute
        require(_emergencyThreshold <= 10000, "Invalid threshold");
        
        baseLiquidationReward = _baseLiquidationReward;
        maxLiquidationReward = _maxLiquidationReward;
        liquidationDelay = _liquidationDelay;
        emergencyLiquidationThreshold = _emergencyThreshold;
    }
}
