"use client"

import { useState, useEffect } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { TrendingUp, TrendingDown, Activity, DollarSign } from "lucide-react"

interface BasePair {
  symbol: string
  baseToken: string
  quoteToken: string
  lastPrice: number
  change24h: number
  changePercent: number
  volume24h: number
  high24h: number
  low24h: number
  isActive: boolean
}

export function BasePairsWidget() {
  const [basePairs, setBasePairs] = useState<BasePair[]>([
    {
      symbol: "ETH/USDbC",
      baseToken: "ETH",
      quoteToken: "USDbC",
      lastPrice: 2456.78,
      change24h: 45.23,
      changePercent: 1.87,
      volume24h: 12500000,
      high24h: 2489.45,
      low24h: 2398.12,
      isActive: true,
    },
    {
      symbol: "cbETH/ETH",
      baseToken: "cbETH",
      quoteToken: "ETH",
      lastPrice: 1.0023,
      change24h: 0.0015,
      changePercent: 0.15,
      volume24h: 3200000,
      high24h: 1.0045,
      low24h: 0.9998,
      isActive: true,
    },
    {
      symbol: "DAI/USDbC",
      baseToken: "DAI",
      quoteToken: "USDbC",
      lastPrice: 0.9998,
      change24h: -0.0002,
      changePercent: -0.02,
      volume24h: 8900000,
      high24h: 1.0012,
      low24h: 0.9985,
      isActive: true,
    },
    {
      symbol: "AERO/ETH",
      baseToken: "AERO",
      quoteToken: "ETH",
      lastPrice: 0.0005234,
      change24h: 0.0000123,
      changePercent: 2.41,
      volume24h: 1800000,
      high24h: 0.0005456,
      low24h: 0.0004987,
      isActive: true,
    },
    {
      symbol: "BASE/ETH",
      baseToken: "BASE",
      quoteToken: "ETH",
      lastPrice: 0.001234,
      change24h: -0.000045,
      changePercent: -3.52,
      volume24h: 950000,
      high24h: 0.001298,
      low24h: 0.001187,
      isActive: true,
    },
    {
      symbol: "BASE/ETH(Sepolia)",
      baseToken: "BASE",
      quoteToken: "ETH",
      lastPrice: 0.0008234,
      change24h: 0.000012,
      changePercent: 1.48,
      volume24h: 450000,
      high24h: 0.0008456,
      low24h: 0.0007987,
      isActive: true,
    },
  ])

  const [selectedPair, setSelectedPair] = useState("ETH/USDbC")

  useEffect(() => {
    // Simulate real-time price updates
    const interval = setInterval(() => {
      setBasePairs((prev) =>
        prev.map((pair) => ({
          ...pair,
          lastPrice: pair.lastPrice * (1 + (Math.random() - 0.5) * 0.01),
          change24h: pair.change24h + (Math.random() - 0.5) * 0.5,
          changePercent: pair.changePercent + (Math.random() - 0.5) * 0.1,
        })),
      )
    }, 3000)

    return () => clearInterval(interval)
  }, [])

  const formatPrice = (price: number, symbol: string) => {
    if (symbol.includes("ETH") && !symbol.startsWith("ETH")) {
      return price.toFixed(6)
    }
    if (symbol.includes("USDbC") || symbol.includes("DAI")) {
      return price.toFixed(4)
    }
    if (symbol.includes("Sepolia")) {
      return price.toFixed(7) // More precision for testnet
    }
    return price.toFixed(2)
  }

  const formatVolume = (volume: number) => {
    if (volume >= 1000000) {
      return `$${(volume / 1000000).toFixed(1)}M`
    }
    return `$${(volume / 1000).toFixed(0)}K`
  }

  return (
    <Card className="bg-slate-900/50 border-slate-800">
      <CardHeader>
        <CardTitle className="text-white flex items-center">
          <Activity className="w-5 h-5 mr-2 text-blue-400" />
          Base Ecosystem Pairs
        </CardTitle>
        <div className="flex items-center space-x-2">
          <Badge variant="outline" className="border-blue-500 text-blue-400">
            <div className="w-2 h-2 bg-blue-400 rounded-full mr-2 animate-pulse"></div>
            Base Network
          </Badge>
          <Badge variant="outline" className="border-green-500 text-green-400">
            5 Active Pairs
          </Badge>
        </div>
      </CardHeader>
      <CardContent>
        <div className="space-y-3">
          {basePairs.map((pair) => (
            <div
              key={pair.symbol}
              className={`p-4 rounded-lg border transition-all cursor-pointer ${
                selectedPair === pair.symbol
                  ? "border-blue-500 bg-blue-500/10"
                  : "border-slate-700 bg-slate-800/30 hover:bg-slate-800/50"
              }`}
              onClick={() => setSelectedPair(pair.symbol)}
            >
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-3">
                  <div>
                    <div className="font-semibold text-white text-lg">{pair.symbol}</div>
                    <div className="text-sm text-slate-400">
                      {pair.baseToken} ↔ {pair.quoteToken}
                    </div>
                  </div>
                  {pair.symbol === "ETH/USDbC" && (
                    <Badge variant="outline" className="border-yellow-500 text-yellow-400">
                      Primary
                    </Badge>
                  )}
                  {pair.symbol === "cbETH/ETH" && (
                    <Badge variant="outline" className="border-purple-500 text-purple-400">
                      Arbitrage
                    </Badge>
                  )}
                  {pair.symbol === "DAI/USDbC" && (
                    <Badge variant="outline" className="border-green-500 text-green-400">
                      Stable
                    </Badge>
                  )}
                  {pair.symbol.includes("Sepolia") && (
                    <Badge variant="outline" className="border-orange-500 text-orange-400">
                      Testnet
                    </Badge>
                  )}
                </div>

                <div className="text-right">
                  <div className="text-xl font-bold text-white">${formatPrice(pair.lastPrice, pair.symbol)}</div>
                  <div
                    className={`flex items-center text-sm ${
                      pair.changePercent >= 0 ? "text-green-400" : "text-red-400"
                    }`}
                  >
                    {pair.changePercent >= 0 ? (
                      <TrendingUp className="w-3 h-3 mr-1" />
                    ) : (
                      <TrendingDown className="w-3 h-3 mr-1" />
                    )}
                    {pair.changePercent >= 0 ? "+" : ""}
                    {pair.changePercent.toFixed(2)}%
                  </div>
                </div>
              </div>

              <div className="mt-3 grid grid-cols-3 gap-4 text-sm">
                <div>
                  <div className="text-slate-400">24h Volume</div>
                  <div className="text-white font-semibold">{formatVolume(pair.volume24h)}</div>
                </div>
                <div>
                  <div className="text-slate-400">24h High</div>
                  <div className="text-white font-semibold">${formatPrice(pair.high24h, pair.symbol)}</div>
                </div>
                <div>
                  <div className="text-slate-400">24h Low</div>
                  <div className="text-white font-semibold">${formatPrice(pair.low24h, pair.symbol)}</div>
                </div>
              </div>

              {selectedPair === pair.symbol && (
                <div className="mt-4 pt-3 border-t border-slate-700">
                  <div className="flex space-x-2">
                    <Button size="sm" className="bg-green-600 hover:bg-green-700 text-white">
                      Buy {pair.baseToken}
                    </Button>
                    <Button
                      size="sm"
                      variant="outline"
                      className="border-red-500 text-red-400 hover:bg-red-500/10 bg-transparent"
                    >
                      Sell {pair.baseToken}
                    </Button>
                    <Button
                      size="sm"
                      variant="outline"
                      className="border-blue-500 text-blue-400 hover:bg-blue-500/10 bg-transparent"
                    >
                      View Chart
                    </Button>
                  </div>
                </div>
              )}
            </div>
          ))}
        </div>

        {/* Base Network Stats */}
        <div className="mt-6 p-4 bg-gradient-to-r from-blue-900/30 to-purple-900/30 rounded-lg border border-slate-700">
          <h4 className="text-white font-semibold mb-3 flex items-center">
            <DollarSign className="w-4 h-4 mr-2 text-blue-400" />
            Base Network Statistics
          </h4>
          <div className="grid grid-cols-2 gap-4 text-sm">
            <div>
              <div className="text-slate-400">Total Volume (24h)</div>
              <div className="text-white font-semibold">$27.35M</div>
            </div>
            <div>
              <div className="text-slate-400">Active Traders</div>
              <div className="text-white font-semibold">2,847</div>
            </div>
            <div>
              <div className="text-slate-400">Total Liquidity</div>
              <div className="text-white font-semibold">$156.8M</div>
            </div>
            <div>
              <div className="text-slate-400">Avg. Spread</div>
              <div className="text-white font-semibold">0.08%</div>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  )
}
