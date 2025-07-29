"use client"

import { useState, useEffect } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { TestTube, Coins, TrendingUp, RefreshCw, Zap, Clock, AlertTriangle } from "lucide-react"

interface TestnetStatus {
  isRegistered: boolean
  lastFaucetClaim: number
  nextClaimTime: number
  baseBalance: number
  ethBalance: number
  canClaim: boolean
}

export function SepoliaTestnetWidget() {
  const [testnetStatus, setTestnetStatus] = useState<TestnetStatus>({
    isRegistered: false,
    lastFaucetClaim: 0,
    nextClaimTime: 0,
    baseBalance: 0,
    ethBalance: 0,
    canClaim: true,
  })

  const [sepoliaPrice, setSepoliaPrice] = useState(0.0008234)
  const [priceChange, setPriceChange] = useState("")
  const [isSimulating, setIsSimulating] = useState(false)
  const [tradeAmount, setTradeAmount] = useState("")
  const [isClaiming, setIsClaiming] = useState(false)

  useEffect(() => {
    // Simulate testnet status
    const mockStatus: TestnetStatus = {
      isRegistered: true,
      lastFaucetClaim: Date.now() - 3600000, // 1 hour ago
      nextClaimTime: Date.now() + 82800000, // 23 hours from now
      baseBalance: 8750.5,
      ethBalance: 2.45,
      canClaim: false,
    }
    setTestnetStatus(mockStatus)

    // Simulate price updates
    const interval = setInterval(() => {
      setSepoliaPrice((prev) => prev * (1 + (Math.random() - 0.5) * 0.02))
    }, 5000)

    return () => clearInterval(interval)
  }, [])

  const handleClaimTokens = async () => {
    setIsClaiming(true)

    // Simulate API call
    await new Promise((resolve) => setTimeout(resolve, 2000))

    setTestnetStatus((prev) => ({
      ...prev,
      baseBalance: prev.baseBalance + 10000,
      ethBalance: prev.ethBalance + 5,
      lastFaucetClaim: Date.now(),
      nextClaimTime: Date.now() + 86400000,
      canClaim: false,
    }))

    setIsClaiming(false)
  }

  const handleSimulatePrice = async () => {
    if (!priceChange) return

    setIsSimulating(true)

    // Simulate price change
    const changePercent = Number.parseFloat(priceChange) / 100
    setSepoliaPrice((prev) => prev * (1 + changePercent))

    await new Promise((resolve) => setTimeout(resolve, 1000))
    setIsSimulating(false)
    setPriceChange("")
  }

  const handleTestTrade = async () => {
    if (!tradeAmount) return

    // Simulate trade execution
    console.log("Executing testnet trade:", tradeAmount, "BASE tokens")

    // Update balance
    setTestnetStatus((prev) => ({
      ...prev,
      baseBalance: prev.baseBalance - Number.parseFloat(tradeAmount),
      ethBalance: prev.ethBalance + Number.parseFloat(tradeAmount) * sepoliaPrice,
    }))

    setTradeAmount("")
  }

  const timeUntilNextClaim = Math.max(0, testnetStatus.nextClaimTime - Date.now())
  const hoursUntilClaim = Math.floor(timeUntilNextClaim / (1000 * 60 * 60))
  const minutesUntilClaim = Math.floor((timeUntilNextClaim % (1000 * 60 * 60)) / (1000 * 60))

  return (
    <Card className="bg-gradient-to-br from-orange-900/20 to-yellow-900/20 border-orange-500/30">
      <CardHeader>
        <CardTitle className="text-white flex items-center">
          <TestTube className="w-5 h-5 mr-2 text-orange-400" />
          Sepolia Testnet Trading
        </CardTitle>
        <div className="flex items-center space-x-2">
          <Badge variant="outline" className="border-orange-500 text-orange-400">
            <div className="w-2 h-2 bg-orange-400 rounded-full mr-2 animate-pulse"></div>
            Sepolia Network
          </Badge>
          <Badge variant="outline" className="border-yellow-500 text-yellow-400">
            BASE/ETH(Sepolia)
          </Badge>
        </div>
      </CardHeader>
      <CardContent className="space-y-6">
        {/* Current Price */}
        <div className="p-4 bg-slate-800/50 rounded-lg">
          <div className="flex items-center justify-between mb-2">
            <span className="text-slate-400">BASE/ETH(Sepolia) Price</span>
            <div className="flex items-center text-green-400">
              <TrendingUp className="w-3 h-3 mr-1" />
              +1.48%
            </div>
          </div>
          <div className="text-2xl font-bold text-white">{sepoliaPrice.toFixed(7)} ETH</div>
          <div className="text-sm text-slate-400">≈ ${(sepoliaPrice * 2456).toFixed(4)} USD</div>
        </div>

        {/* Testnet Status */}
        <div className="grid grid-cols-2 gap-4">
          <div className="p-3 bg-slate-800/30 rounded-lg">
            <div className="text-slate-400 text-sm">BASE Balance</div>
            <div className="text-white font-semibold">{testnetStatus.baseBalance.toLocaleString()} BASE</div>
          </div>
          <div className="p-3 bg-slate-800/30 rounded-lg">
            <div className="text-slate-400 text-sm">ETH Balance</div>
            <div className="text-white font-semibold">{testnetStatus.ethBalance.toFixed(3)} ETH</div>
          </div>
        </div>

        {/* Faucet Section */}
        <div className="p-4 bg-blue-900/20 rounded-lg border border-blue-500/30">
          <div className="flex items-center justify-between mb-3">
            <h4 className="text-white font-semibold flex items-center">
              <Coins className="w-4 h-4 mr-2 text-blue-400" />
              Testnet Faucet
            </h4>
            {!testnetStatus.canClaim && (
              <div className="flex items-center text-orange-400 text-sm">
                <Clock className="w-3 h-3 mr-1" />
                {hoursUntilClaim}h {minutesUntilClaim}m
              </div>
            )}
          </div>

          <p className="text-slate-300 text-sm mb-3">Claim 10,000 BASE tokens and 5 ETH for testing (once per 24h)</p>

          <Button
            onClick={handleClaimTokens}
            disabled={!testnetStatus.canClaim || isClaiming}
            className="w-full bg-blue-600 hover:bg-blue-700 disabled:opacity-50"
          >
            {isClaiming ? (
              <>
                <RefreshCw className="w-4 h-4 mr-2 animate-spin" />
                Claiming...
              </>
            ) : testnetStatus.canClaim ? (
              "Claim Test Tokens"
            ) : (
              `Next claim in ${hoursUntilClaim}h ${minutesUntilClaim}m`
            )}
          </Button>
        </div>

        {/* Price Simulation */}
        <div className="p-4 bg-purple-900/20 rounded-lg border border-purple-500/30">
          <h4 className="text-white font-semibold mb-3 flex items-center">
            <Zap className="w-4 h-4 mr-2 text-purple-400" />
            Price Simulation
          </h4>

          <div className="flex space-x-2 mb-3">
            <div className="flex-1">
              <Label className="text-slate-300 text-sm">Price Change %</Label>
              <Input
                value={priceChange}
                onChange={(e) => setPriceChange(e.target.value)}
                placeholder="e.g., +5 or -3"
                className="bg-slate-800 border-slate-700"
              />
            </div>
            <div className="flex items-end">
              <Button
                onClick={handleSimulatePrice}
                disabled={!priceChange || isSimulating}
                size="sm"
                className="bg-purple-600 hover:bg-purple-700"
              >
                {isSimulating ? <RefreshCw className="w-4 h-4 animate-spin" /> : "Simulate"}
              </Button>
            </div>
          </div>

          <div className="text-xs text-slate-400">Test price movements between -50% to +50%</div>
        </div>

        {/* Test Trading */}
        <div className="p-4 bg-green-900/20 rounded-lg border border-green-500/30">
          <h4 className="text-white font-semibold mb-3 flex items-center">
            <TrendingUp className="w-4 h-4 mr-2 text-green-400" />
            Test Trading
          </h4>

          <div className="flex space-x-2 mb-3">
            <div className="flex-1">
              <Label className="text-slate-300 text-sm">Amount (BASE)</Label>
              <Input
                value={tradeAmount}
                onChange={(e) => setTradeAmount(e.target.value)}
                placeholder="100"
                className="bg-slate-800 border-slate-700"
              />
            </div>
            <div className="flex items-end">
              <Button
                onClick={handleTestTrade}
                disabled={!tradeAmount || Number.parseFloat(tradeAmount) > testnetStatus.baseBalance}
                size="sm"
                className="bg-green-600 hover:bg-green-700"
              >
                Sell BASE
              </Button>
            </div>
          </div>

          {tradeAmount && (
            <div className="text-xs text-slate-400">
              You'll receive ≈ {(Number.parseFloat(tradeAmount) * sepoliaPrice).toFixed(6)} ETH
            </div>
          )}
        </div>

        {/* Testnet Warning */}
        <div className="p-3 bg-yellow-900/20 rounded-lg border border-yellow-500/30">
          <div className="flex items-start space-x-2">
            <AlertTriangle className="w-4 h-4 text-yellow-400 mt-0.5" />
            <div>
              <div className="text-yellow-400 font-medium text-sm">Testnet Only</div>
              <div className="text-slate-300 text-xs">
                This is Sepolia testnet. Tokens have no real value. Use for testing NEXUS features before mainnet
                deployment.
              </div>
            </div>
          </div>
        </div>

        {/* Quick Actions */}
        <div className="grid grid-cols-2 gap-3">
          <Button variant="outline" className="border-blue-500 text-blue-400 hover:bg-blue-500/10 bg-transparent">
            View Testnet Explorer
          </Button>
          <Button variant="outline" className="border-orange-500 text-orange-400 hover:bg-orange-500/10 bg-transparent">
            Reset Test Data
          </Button>
        </div>
      </CardContent>
    </Card>
  )
}
