// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./NexusCrossMargin.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title NexusOptionsAMM
 * @dev Automated Market Maker for options with dynamic pricing
 * Integrates with cross-margin system for capital efficiency
 */
contract NexusOptionsAMM is ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    // Black-Scholes constants
    uint256 constant SECONDS_PER_YEAR = 31536000;
    uint256 constant PRECISION = 1e18;
    uint256 constant SQRT_2PI = 2506628274631000502; // sqrt(2*pi) * 1e18

    struct Option {
        address underlying;
        uint256 strike;
        uint256 expiry;
        bool isCall;
        uint256 premium;
        uint256 totalSupply;
        uint256 openInterest;
        bool isActive;
    }

    struct OptionPosition {
        uint256 optionId;
        uint256 amount;
        bool isLong;
        uint256 entryTime;
        uint256 premiumPaid;
    }

    struct Greeks {
        int256 delta;    // Price sensitivity
        uint256 gamma;   // Delta sensitivity
        uint256 theta;   // Time decay
        uint256 vega;    // Volatility sensitivity
        uint256 rho;     // Interest rate sensitivity
    }

    mapping(uint256 => Option) public options;
    mapping(address => mapping(uint256 => OptionPosition)) public userPositions;
    mapping(address => uint256) public positionCounts;
    mapping(uint256 => Greeks) public optionGreeks;

    NexusCrossMargin public crossMargin;
    address public volatilityOracle;
    address public riskFreeRate;

    uint256 public nextOptionId = 1;
    uint256 public defaultVolatility = 80; // 80% default volatility
    uint256 public riskFreeRateValue = 500; // 5% risk-free rate

    event OptionCreated(
        uint256 indexed optionId,
        address indexed underlying,
        uint256 strike,
        uint256 expiry,
        bool isCall
    );

    event OptionTraded(
        address indexed trader,
        uint256 indexed optionId,
        uint256 amount,
        uint256 premium,
        bool isLong
    );

    event GreeksUpdated(
        uint256 indexed optionId,
        int256 delta,
        uint256 gamma,
        uint256 theta,
        uint256 vega
    );

    constructor(address _crossMargin, address _volatilityOracle) {
        crossMargin = NexusCrossMargin(_crossMargin);
        volatilityOracle = _volatilityOracle;
    }

    /**
     * @dev Create a new options contract
     */
    function createOption(
        address underlying,
        uint256 strike,
        uint256 expiry,
        bool isCall
    ) external onlyOwner returns (uint256) {
        require(expiry > block.timestamp, "Invalid expiry");
        require(strike > 0, "Invalid strike");

        uint256 optionId = nextOptionId++;
        
        options[optionId] = Option({
            underlying: underlying,
            strike: strike,
            expiry: expiry,
            isCall: isCall,
            premium: 0,
            totalSupply: 0,
            openInterest: 0,
            isActive: true
        });

        // Calculate initial premium and Greeks
        updateOptionPricing(optionId);

        emit OptionCreated(optionId, underlying, strike, expiry, isCall);
        return optionId;
    }

    /**
     * @dev Buy options (long position)
     */
    function buyOption(
        uint256 optionId,
        uint256 amount,
        uint256 maxPremium
    ) external nonReentrant {
        Option storage option = options[optionId];
        require(option.isActive, "Option not active");
        require(option.expiry > block.timestamp, "Option expired");

        // Update pricing before trade
        updateOptionPricing(optionId);
        
        uint256 totalPremium = option.premium.mul(amount).div(PRECISION);
        require(totalPremium <= maxPremium, "Premium too high");

        // Check margin requirements through cross-margin system
        uint256 availableMargin = crossMargin.getAvailableMargin(msg.sender);
        require(availableMargin >= totalPremium, "Insufficient margin");

        // Create position
        uint256 positionId = positionCounts[msg.sender]++;
        userPositions[msg.sender][positionId] = OptionPosition({
            optionId: optionId,
            amount: amount,
            isLong: true,
            entryTime: block.timestamp,
            premiumPaid: totalPremium
        });

        // Update option data
        option.openInterest = option.openInterest.add(amount);
        option.totalSupply = option.totalSupply.add(amount);

        // Transfer premium (integrated with cross-margin)
        // This would interact with the cross-margin contract

        emit OptionTraded(msg.sender, optionId, amount, totalPremium, true);
    }

    /**
     * @dev Sell options (short position)
     */
    function sellOption(
        uint256 optionId,
        uint256 amount,
        uint256 minPremium
    ) external nonReentrant {
        Option storage option = options[optionId];
        require(option.isActive, "Option not active");
        require(option.expiry > block.timestamp, "Option expired");

        updateOptionPricing(optionId);
        
        uint256 totalPremium = option.premium.mul(amount).div(PRECISION);
        require(totalPremium >= minPremium, "Premium too low");

        // Calculate margin requirement for short position
        uint256 marginRequired = calculateShortMargin(optionId, amount);
        uint256 availableMargin = crossMargin.getAvailableMargin(msg.sender);
        require(availableMargin >= marginRequired, "Insufficient margin");

        // Create position
        uint256 positionId = positionCounts[msg.sender]++;
        userPositions[msg.sender][positionId] = OptionPosition({
            optionId: optionId,
            amount: amount,
            isLong: false,
            entryTime: block.timestamp,
            premiumPaid: 0
        });

        option.openInterest = option.openInterest.add(amount);

        emit OptionTraded(msg.sender, optionId, amount, totalPremium, false);
    }

    /**
     * @dev Exercise option at expiry
     */
    function exerciseOption(uint256 positionId) external {
        OptionPosition storage position = userPositions[msg.sender][positionId];
        Option storage option = options[position.optionId];
        
        require(position.isLong, "Only long positions can exercise");
        require(block.timestamp >= option.expiry, "Not yet expired");
        require(position.amount > 0, "No position to exercise");

        uint256 currentPrice = getCurrentPrice(option.underlying);
        uint256 payoff = 0;

        if (option.isCall && currentPrice > option.strike) {
            payoff = currentPrice.sub(option.strike).mul(position.amount).div(PRECISION);
        } else if (!option.isCall && option.strike > currentPrice) {
            payoff = option.strike.sub(currentPrice).mul(position.amount).div(PRECISION);
        }

        if (payoff > 0) {
            // Process exercise through cross-margin system
            // This would update the user's collateral
        }

        // Clear position
        position.amount = 0;
    }

    /**
     * @dev Update option pricing using Black-Scholes model
     */
    function updateOptionPricing(uint256 optionId) public {
        Option storage option = options[optionId];
        require(option.isActive, "Option not active");

        uint256 currentPrice = getCurrentPrice(option.underlying);
        uint256 timeToExpiry = option.expiry > block.timestamp ? 
            option.expiry.sub(block.timestamp) : 0;
        
        if (timeToExpiry == 0) {
            option.premium = calculateIntrinsicValue(optionId, currentPrice);
            return;
        }

        uint256 volatility = getVolatility(option.underlying);
        
        // Black-Scholes calculation
        (uint256 premium, Greeks memory greeks) = calculateBlackScholes(
            currentPrice,
            option.strike,
            timeToExpiry,
            volatility,
            riskFreeRateValue,
            option.isCall
        );

        option.premium = premium;
        optionGreeks[optionId] = greeks;

        emit GreeksUpdated(optionId, greeks.delta, greeks.gamma, greeks.theta, greeks.vega);
    }

    /**
     * @dev Calculate Black-Scholes option price and Greeks
     */
    function calculateBlackScholes(
        uint256 spot,
        uint256 strike,
        uint256 timeToExpiry,
        uint256 volatility,
        uint256 riskFree,
        bool isCall
    ) internal pure returns (uint256 premium, Greeks memory greeks) {
        // Simplified Black-Scholes implementation
        // In production, this would use more sophisticated math libraries
        
        uint256 sqrtTime = sqrt(timeToExpiry.mul(PRECISION).div(SECONDS_PER_YEAR));
        uint256 d1 = calculateD1(spot, strike, timeToExpiry, volatility, riskFree);
        uint256 d2 = d1 > volatility.mul(sqrtTime).div(PRECISION) ? 
            d1.sub(volatility.mul(sqrtTime).div(PRECISION)) : 0;

        uint256 nd1 = normalCDF(d1);
        uint256 nd2 = normalCDF(d2);

        if (isCall) {
            premium = spot.mul(nd1).div(PRECISION).sub(
                strike.mul(nd2).mul(
                    exp(riskFree.mul(timeToExpiry).div(SECONDS_PER_YEAR).div(100))
                ).div(PRECISION).div(PRECISION)
            );
        } else {
            premium = strike.mul(PRECISION.sub(nd2)).mul(
                exp(riskFree.mul(timeToExpiry).div(SECONDS_PER_YEAR).div(100))
            ).div(PRECISION).div(PRECISION).sub(
                spot.mul(PRECISION.sub(nd1)).div(PRECISION)
            );
        }

        // Calculate Greeks (simplified)
        greeks.delta = isCall ? int256(nd1) : int256(nd1) - int256(PRECISION);
        greeks.gamma = normalPDF(d1).mul(PRECISION).div(spot.mul(volatility).mul(sqrtTime).div(PRECISION));
        greeks.theta = calculateTheta(spot, strike, timeToExpiry, volatility, riskFree, isCall);
        greeks.vega = spot.mul(normalPDF(d1)).mul(sqrtTime).div(PRECISION).div(100);
        greeks.rho = isCall ? 
            strike.mul(timeToExpiry).mul(nd2).div(SECONDS_PER_YEAR).div(100) :
            strike.mul(timeToExpiry).mul(PRECISION.sub(nd2)).div(SECONDS_PER_YEAR).div(100);
    }

    /**
     * @dev Calculate margin requirement for short option position
     */
    function calculateShortMargin(uint256 optionId, uint256 amount) internal view returns (uint256) {
        Option memory option = options[optionId];
        uint256 currentPrice = getCurrentPrice(option.underlying);
        
        // Standard margin calculation: 20% of underlying + premium - out-of-money amount
        uint256 baseMargin = currentPrice.mul(amount).mul(20).div(100).div(PRECISION);
        uint256 premium = option.premium.mul(amount).div(PRECISION);
        
        uint256 otmAmount = 0;
        if (option.isCall && option.strike > currentPrice) {
            otmAmount = option.strike.sub(currentPrice).mul(amount).div(PRECISION);
        } else if (!option.isCall && currentPrice > option.strike) {
            otmAmount = currentPrice.sub(option.strike).mul(amount).div(PRECISION);
        }

        uint256 totalMargin = baseMargin.add(premium);
        return totalMargin > otmAmount ? totalMargin.sub(otmAmount) : totalMargin;
    }

    /**
     * @dev Calculate intrinsic value of option
     */
    function calculateIntrinsicValue(uint256 optionId, uint256 currentPrice) internal view returns (uint256) {
        Option memory option = options[optionId];
        
        if (option.isCall && currentPrice > option.strike) {
            return currentPrice.sub(option.strike);
        } else if (!option.isCall && option.strike > currentPrice) {
            return option.strike.sub(currentPrice);
        }
        
        return 0;
    }

    // Mathematical helper functions (simplified implementations)
    function calculateD1(
        uint256 spot,
        uint256 strike,
        uint256 timeToExpiry,
        uint256 volatility,
        uint256 riskFree
    ) internal pure returns (uint256) {
        // Simplified d1 calculation
        return PRECISION.div(2); // Placeholder
    }

    function calculateTheta(
        uint256 spot,
        uint256 strike,
        uint256 timeToExpiry,
        uint256 volatility,
        uint256 riskFree,
        bool isCall
    ) internal pure returns (uint256) {
        // Simplified theta calculation
        return volatility.mul(spot).div(365); // Daily time decay approximation
    }

    function normalCDF(uint256 x) internal pure returns (uint256) {
        // Simplified normal CDF approximation
        if (x >= PRECISION.div(2)) return PRECISION.mul(75).div(100); // ~0.75
        return PRECISION.mul(25).div(100); // ~0.25
    }

    function normalPDF(uint256 x) internal pure returns (uint256) {
        // Simplified normal PDF
        return PRECISION.mul(40).div(100); // ~0.4
    }

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

    function exp(uint256 x) internal pure returns (uint256) {
        // Simplified exponential function
        return PRECISION.add(x); // Linear approximation
    }

    function getCurrentPrice(address asset) internal view returns (uint256) {
        // Get price from cross-margin contract or oracle
        return 2500 * PRECISION; // Placeholder
    }

    function getVolatility(address asset) internal view returns (uint256) {
        // Get volatility from oracle
        return defaultVolatility;
    }

    /**
     * @dev Get option details with current pricing
     */
    function getOptionDetails(uint256 optionId) external view returns (
        address underlying,
        uint256 strike,
        uint256 expiry,
        bool isCall,
        uint256 premium,
        uint256 openInterest,
        Greeks memory greeks
    ) {
        Option memory option = options[optionId];
        return (
            option.underlying,
            option.strike,
            option.expiry,
            option.isCall,
            option.premium,
            option.openInterest,
            optionGreeks[optionId]
        );
    }

    /**
     * @dev Get user's option positions
     */
    function getUserPositions(address user) external view returns (
        uint256[] memory optionIds,
        uint256[] memory amounts,
        bool[] memory isLong,
        uint256[] memory currentValues
    ) {
        uint256 count = positionCounts[user];
        optionIds = new uint256[](count);
        amounts = new uint256[](count);
        isLong = new bool[](count);
        currentValues = new uint256[](count);

        for (uint256 i = 0; i < count; i++) {
            OptionPosition memory position = userPositions[user][i];
            optionIds[i] = position.optionId;
            amounts[i] = position.amount;
            isLong[i] = position.isLong;
            
            if (position.amount > 0) {
                Option memory option = options[position.optionId];
                currentValues[i] = option.premium.mul(position.amount).div(PRECISION);
            }
        }
    }
}
