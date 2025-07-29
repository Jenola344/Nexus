// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./NexusCrossMargin.sol";

/**
 * @title NexusSyntheticAssets
 * @dev Community-created synthetic assets with automated pricing
 * Integrates with cross-margin system for capital efficiency
 */
contract NexusSyntheticAssets is ReentrancyGuard, Ownable {
    
    struct SyntheticAsset {
        string name;
        string symbol;
        address tokenAddress;
        address creator;
        uint256 totalSupply;
        uint256 collateralRatio;     // Required collateral ratio (e.g., 150%)
        uint256 liquidationRatio;    // Liquidation threshold (e.g., 120%)
        uint256 stabilityFee;        // Annual stability fee (e.g., 2%)
        uint256 creationTime;
        bool isActive;
        string priceFormula;         // IPFS hash of pricing formula
        address[] priceFeeds;        // Oracle addresses for pricing
        uint256[] feedWeights;       // Weights for price feeds
    }

    struct SyntheticPosition {
        uint256 assetId;
        uint256 collateralAmount;
        uint256 syntheticAmount;
        uint256 entryTime;
        uint256 accumulatedFees;
        bool isActive;
    }

    struct PriceData {
        uint256 price;
        uint256 timestamp;
        uint256 confidence;
        bool isValid;
    }

    mapping(uint256 => SyntheticAsset) public syntheticAssets;
    mapping(address => mapping(uint256 => SyntheticPosition)) public userPositions;
    mapping(address => uint256) public positionCounts;
    mapping(uint256 => PriceData) public assetPrices;
    mapping(address => bool) public authorizedOracles;
    mapping(uint256 => mapping(address => uint256)) public assetBalances;

    NexusCrossMargin public crossMargin;
    address public collateralToken; // USDC on Base
    
    uint256 public nextAssetId = 1;
    uint256 public minCollateralRatio = 12000; // 120% minimum
    uint256 public maxCollateralRatio = 50000; // 500% maximum
    uint256 public creationFee = 1000 * 1e6; // 1000 USDC
    uint256 public governanceDelay = 86400; // 24 hours

    event SyntheticAssetCreated(
        uint256 indexed assetId,
        string name,
        string symbol,
        address indexed creator,
        address tokenAddress
    );

    event SyntheticMinted(
        address indexed user,
        uint256 indexed assetId,
        uint256 collateralAmount,
        uint256 syntheticAmount
    );

    event SyntheticBurned(
        address indexed user,
        uint256 indexed assetId,
        uint256 collateralReleased,
        uint256 syntheticAmount
    );

    event PositionLiquidated(
        address indexed user,
        uint256 indexed assetId,
        uint256 collateralSeized,
        uint256 syntheticBurned
    );

    event PriceUpdated(
        uint256 indexed assetId,
        uint256 newPrice,
        uint256 confidence
    );

    modifier validAsset(uint256 assetId) {
        require(assetId < nextAssetId && syntheticAssets[assetId].isActive, "Invalid asset");
        _;
    }

    modifier onlyAuthorizedOracle() {
        require(authorizedOracles[msg.sender], "Not authorized oracle");
        _;
    }

    constructor(address _crossMargin, address _collateralToken) {
        crossMargin = NexusCrossMargin(_crossMargin);
        collateralToken = _collateralToken;
    }

    /**
     * @dev Create a new synthetic asset
     */
    function createSyntheticAsset(
        string memory name,
        string memory symbol,
        uint256 collateralRatio,
        uint256 liquidationRatio,
        uint256 stabilityFee,
        string memory priceFormula,
        address[] memory priceFeeds,
        uint256[] memory feedWeights
    ) external payable nonReentrant {
        require(bytes(name).length > 0 && bytes(symbol).length > 0, "Invalid name/symbol");
        require(collateralRatio >= minCollateralRatio && collateralRatio <= maxCollateralRatio, "Invalid collateral ratio");
        require(liquidationRatio < collateralRatio, "Invalid liquidation ratio");
        require(stabilityFee <= 2000, "Stability fee too high"); // Max 20%
        require(priceFeeds.length == feedWeights.length, "Array length mismatch");
        require(priceFeeds.length > 0, "Need at least one price feed");

        // Charge creation fee
        IERC20(collateralToken).transferFrom(msg.sender, address(this), creationFee);

        // Validate feed weights sum to 100%
        uint256 totalWeight = 0;
        for (uint256 i = 0; i < feedWeights.length; i++) {
            totalWeight += feedWeights[i];
        }
        require(totalWeight == 10000, "Weights must sum to 100%");

        // Deploy synthetic token
        SyntheticToken synToken = new SyntheticToken(name, symbol, address(this));

        uint256 assetId = nextAssetId++;
        
        syntheticAssets[assetId] = SyntheticAsset({
            name: name,
            symbol: symbol,
            tokenAddress: address(synToken),
            creator: msg.sender,
            totalSupply: 0,
            collateralRatio: collateralRatio,
            liquidationRatio: liquidationRatio,
            stabilityFee: stabilityFee,
            creationTime: block.timestamp,
            isActive: true,
            priceFormula: priceFormula,
            priceFeeds: priceFeeds,
            feedWeights: feedWeights
        });

        emit SyntheticAssetCreated(assetId, name, symbol, msg.sender, address(synToken));
    }

    /**
     * @dev Mint synthetic assets by depositing collateral
     */
    function mintSynthetic(
        uint256 assetId,
        uint256 collateralAmount,
        uint256 syntheticAmount
    ) external nonReentrant validAsset(assetId) {
        require(collateralAmount > 0 && syntheticAmount > 0, "Invalid amounts");

        SyntheticAsset storage asset = syntheticAssets[assetId];
        uint256 currentPrice = getCurrentPrice(assetId);
        require(currentPrice > 0, "Invalid price");

        // Calculate required collateral
        uint256 syntheticValue = syntheticAmount * currentPrice / 1e18;
        uint256 requiredCollateral = syntheticValue * asset.collateralRatio / 10000;
        require(collateralAmount >= requiredCollateral, "Insufficient collateral");

        // Check cross-margin benefits
        uint256 availableMargin = crossMargin.getAvailableMargin(msg.sender);
        uint256 crossMarginDiscount = calculateCrossMarginDiscount(msg.sender, collateralAmount);
        uint256 effectiveCollateral = collateralAmount - crossMarginDiscount;
        
        require(availableMargin >= effectiveCollateral, "Insufficient cross-margin");

        // Transfer collateral
        IERC20(collateralToken).transferFrom(msg.sender, address(this), collateralAmount);

        // Create or update position
        uint256 positionId = positionCounts[msg.sender];
        if (userPositions[msg.sender][positionId].assetId != assetId || 
            !userPositions[msg.sender][positionId].isActive) {
            positionCounts[msg.sender]++;
            positionId = positionCounts[msg.sender] - 1;
        }

        SyntheticPosition storage position = userPositions[msg.sender][positionId];
        position.assetId = assetId;
        position.collateralAmount += collateralAmount;
        position.syntheticAmount += syntheticAmount;
        position.entryTime = block.timestamp;
        position.isActive = true;

        // Mint synthetic tokens
        SyntheticToken(asset.tokenAddress).mint(msg.sender, syntheticAmount);
        asset.totalSupply += syntheticAmount;
        assetBalances[assetId][msg.sender] += syntheticAmount;

        emit SyntheticMinted(msg.sender, assetId, collateralAmount, syntheticAmount);
    }

    /**
     * @dev Burn synthetic assets and withdraw collateral
     */
    function burnSynthetic(
        uint256 positionId,
        uint256 syntheticAmount
    ) external nonReentrant {
        SyntheticPosition storage position = userPositions[msg.sender][positionId];
        require(position.isActive, "Position not active");
        require(syntheticAmount <= position.syntheticAmount, "Insufficient synthetic balance");

        uint256 assetId = position.assetId;
        SyntheticAsset storage asset = syntheticAssets[assetId];

        // Calculate stability fees
        uint256 timeElapsed = block.timestamp - position.entryTime;
        uint256 stabilityFees = calculateStabilityFees(position, timeElapsed);
        position.accumulatedFees += stabilityFees;

        // Calculate collateral to release
        uint256 collateralRatio = position.collateralAmount * 1e18 / position.syntheticAmount;
        uint256 collateralToRelease = syntheticAmount * collateralRatio / 1e18;
        
        // Deduct fees
        if (collateralToRelease > stabilityFees) {
            collateralToRelease -= stabilityFees;
        } else {
            collateralToRelease = 0;
        }

        // Update position
        position.syntheticAmount -= syntheticAmount;
        position.collateralAmount -= (syntheticAmount * position.collateralAmount / (position.syntheticAmount + syntheticAmount));

        if (position.syntheticAmount == 0) {
            position.isActive = false;
        }

        // Burn synthetic tokens
        SyntheticToken(asset.tokenAddress).burn(msg.sender, syntheticAmount);
        asset.totalSupply -= syntheticAmount;
        assetBalances[assetId][msg.sender] -= syntheticAmount;

        // Transfer collateral back to user
        if (collateralToRelease > 0) {
            IERC20(collateralToken).transfer(msg.sender, collateralToRelease);
        }

        emit SyntheticBurned(msg.sender, assetId, collateralToRelease, syntheticAmount);
    }

    /**
     * @dev Liquidate undercollateralized position
     */
    function liquidatePosition(
        address user,
        uint256 positionId
    ) external nonReentrant {
        SyntheticPosition storage position = userPositions[user][positionId];
        require(position.isActive, "Position not active");

        uint256 assetId = position.assetId;
        SyntheticAsset storage asset = syntheticAssets[assetId];
        uint256 currentPrice = getCurrentPrice(assetId);

        // Check if position is undercollateralized
        uint256 syntheticValue = position.syntheticAmount * currentPrice / 1e18;
        uint256 collateralRatio = position.collateralAmount * 10000 / syntheticValue;
        require(collateralRatio < asset.liquidationRatio, "Position not liquidatable");

        // Calculate liquidation amounts
        uint256 liquidationPenalty = position.collateralAmount * 500 / 10000; // 5% penalty
        uint256 liquidatorReward = liquidationPenalty / 2;
        uint256 protocolFee = liquidationPenalty / 2;

        // Burn all synthetic tokens
        SyntheticToken(asset.tokenAddress).burn(user, position.syntheticAmount);
        asset.totalSupply -= position.syntheticAmount;
        assetBalances[assetId][user] -= position.syntheticAmount;

        // Distribute collateral
        uint256 remainingCollateral = position.collateralAmount - liquidationPenalty;
        
        IERC20(collateralToken).transfer(msg.sender, liquidatorReward);
        IERC20(collateralToken).transfer(owner(), protocolFee);
        
        if (remainingCollateral > 0) {
            IERC20(collateralToken).transfer(user, remainingCollateral);
        }

        // Clear position
        position.isActive = false;
        position.collateralAmount = 0;
        position.syntheticAmount = 0;

        emit PositionLiquidated(user, assetId, position.collateralAmount, position.syntheticAmount);
    }

    /**
     * @dev Update price for synthetic asset
     */
    function updatePrice(
        uint256 assetId,
        uint256[] memory prices,
        uint256[] memory confidences
    ) external onlyAuthorizedOracle validAsset(assetId) {
        SyntheticAsset storage asset = syntheticAssets[assetId];
        require(prices.length == asset.priceFeeds.length, "Price array length mismatch");
        require(confidences.length == prices.length, "Confidence array length mismatch");

        uint256 weightedPrice = 0;
        uint256 totalWeight = 0;
        uint256 minConfidence = 10000;

        // Calculate weighted average price
        for (uint256 i = 0; i < prices.length; i++) {
            require(confidences[i] >= 5000, "Confidence too low"); // Min 50%
            
            weightedPrice += prices[i] * asset.feedWeights[i] * confidences[i] / 10000;
            totalWeight += asset.feedWeights[i] * confidences[i] / 10000;
            
            if (confidences[i] < minConfidence) {
                minConfidence = confidences[i];
            }
        }

        require(totalWeight > 0, "No valid prices");
        uint256 finalPrice = weightedPrice / totalWeight;

        assetPrices[assetId] = PriceData({
            price: finalPrice,
            timestamp: block.timestamp,
            confidence: minConfidence,
            isValid: true
        });

        emit PriceUpdated(assetId, finalPrice, minConfidence);
    }

    /**
     * @dev Calculate stability fees for a position
     */
    function calculateStabilityFees(
        SyntheticPosition memory position,
        uint256 timeElapsed
    ) internal view returns (uint256) {
        SyntheticAsset memory asset = syntheticAssets[position.assetId];
        uint256 annualFee = position.syntheticAmount * asset.stabilityFee / 10000;
        return annualFee * timeElapsed / 365 days;
    }

    /**
     * @dev Calculate cross-margin discount
     */
    function calculateCrossMarginDiscount(
        address user,
        uint256 collateralAmount
    ) internal view returns (uint256) {
        uint256 availableMargin = crossMargin.getAvailableMargin(user);
        if (availableMargin == 0) return 0;

        // Up to 10% discount based on cross-margin utilization
        uint256 utilizationRatio = collateralAmount * 10000 / availableMargin;
        if (utilizationRatio > 10000) utilizationRatio = 10000;

        uint256 discount = collateralAmount * (1000 - utilizationRatio / 10) / 10000;
        return discount;
    }

    /**
     * @dev Get current price for synthetic asset
     */
    function getCurrentPrice(uint256 assetId) public view returns (uint256) {
        PriceData memory priceData = assetPrices[assetId];
        require(priceData.isValid, "No valid price");
        require(block.timestamp - priceData.timestamp <= 3600, "Price too old"); // 1 hour max
        return priceData.price;
    }

    /**
     * @dev Get synthetic asset details
     */
    function getSyntheticAsset(uint256 assetId) external view returns (
        string memory name,
        string memory symbol,
        address tokenAddress,
        address creator,
        uint256 totalSupply,
        uint256 collateralRatio,
        uint256 liquidationRatio,
        uint256 currentPrice,
        bool isActive
    ) {
        SyntheticAsset memory asset = syntheticAssets[assetId];
        uint256 price = assetPrices[assetId].isValid ? assetPrices[assetId].price : 0;
        
        return (
            asset.name,
            asset.symbol,
            asset.tokenAddress,
            asset.creator,
            asset.totalSupply,
            asset.collateralRatio,
            asset.liquidationRatio,
            price,
            asset.isActive
        );
    }

    /**
     * @dev Get user position details
     */
    function getUserPosition(
        address user,
        uint256 positionId
    ) external view returns (
        uint256 assetId,
        uint256 collateralAmount,
        uint256 syntheticAmount,
        uint256 currentRatio,
        uint256 liquidationPrice,
        bool isActive
    ) {
        SyntheticPosition memory position = userPositions[user][positionId];
        
        uint256 currentPrice = assetPrices[position.assetId].isValid ? 
            assetPrices[position.assetId].price : 0;
        
        uint256 ratio = 0;
        uint256 liqPrice = 0;
        
        if (position.syntheticAmount > 0 && currentPrice > 0) {
            uint256 syntheticValue = position.syntheticAmount * currentPrice / 1e18;
            ratio = position.collateralAmount * 10000 / syntheticValue;
            
            // Calculate liquidation price
            SyntheticAsset memory asset = syntheticAssets[position.assetId];
            liqPrice = position.collateralAmount * 1e18 * 10000 / 
                      (position.syntheticAmount * asset.liquidationRatio);
        }

        return (
            position.assetId,
            position.collateralAmount,
            position.syntheticAmount,
            ratio,
            liqPrice,
            position.isActive
        );
    }

    /**
     * @dev Add authorized oracle
     */
    function addOracle(address oracle) external onlyOwner {
        authorizedOracles[oracle] = true;
    }

    /**
     * @dev Remove authorized oracle
     */
    function removeOracle(address oracle) external onlyOwner {
        authorizedOracles[oracle] = false;
    }

    /**
     * @dev Emergency pause asset
     */
    function pauseAsset(uint256 assetId) external onlyOwner validAsset(assetId) {
        syntheticAssets[assetId].isActive = false;
    }

    /**
     * @dev Get all active synthetic assets
     */
    function getActiveSyntheticAssets() external view returns (uint256[] memory) {
        uint256 activeCount = 0;
        
        // Count active assets
        for (uint256 i = 1; i < nextAssetId; i++) {
            if (syntheticAssets[i].isActive) {
                activeCount++;
            }
        }

        uint256[] memory activeAssets = new uint256[](activeCount);
        uint256 index = 0;
        
        // Populate active assets array
        for (uint256 i = 1; i < nextAssetId; i++) {
            if (syntheticAssets[i].isActive) {
                activeAssets[index] = i;
                index++;
            }
        }

        return activeAssets;
    }
}

/**
 * @title SyntheticToken
 * @dev ERC20 token for synthetic assets
 */
contract SyntheticToken is ERC20 {
    address public minter;

    modifier onlyMinter() {
        require(msg.sender == minter, "Only minter can call");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address _minter
    ) ERC20(name, symbol) {
        minter = _minter;
    }

    function mint(address to, uint256 amount) external onlyMinter {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyMinter {
        _burn(from, amount);
    }
}
