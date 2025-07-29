"use client"

import { useState } from "react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Progress } from "@/components/ui/progress"
import {
  PieChart,
  BarChart3,
  TrendingUp,
  TrendingDown,
  DollarSign,
  Shield,
  Target,
  Activity,
  Zap,
  Brain,
} from "lucide-react"
import Link from "next/link"

export default function Portfolio() {
  const [timeframe, setTimeframe] = useState("24h")

  const portfolioData = {
    totalValue: 125000,
    pnl24h: 2340,
    pnlPercent: 1.87,
    marginUsed: 45000,
    marginAvailable: 80000,
    positions: 12,
    unrealizedPnL: 1850,
    realizedPnL: 490,
  }

  const assetAllocation = [
    { symbol: "ETH", value: 56250, percentage: 45, pnl: 1250, color: "bg-blue-500" },
    { symbol: "BTC", value: 37500, percentage: 30, pnl: 890, color: "bg-orange-500" },
    { symbol: "SOL", value: 18750, percentage: 15, pnl: -340, color: "bg-purple-500" },
    { symbol: "AVAX", value: 12500, percentage: 10, pnl: 540, color: "bg-red-500" },
  ]

  const performanceMetrics = {
    sharpeRatio: 1.85,
    maxDrawdown: 8.5,
    winRate: 68.4,
    avgWin: 245,
    avgLoss: -180,
    totalTrades: 147,
  }

  return (
    <div className="min-h-screen bg-slate-950">
      {/* Header */}
      <header className="border-b border-slate-800 bg-slate-900/50 backdrop-blur-sm">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-6">
              <Link href="/dashboard" className="flex items-center space-x-2">
                <div className="h-8 w-8 rounded-lg bg-gradient-to-r from-blue-500 to-purple-600 flex items-center justify-center">
                  <span className="text-white font-bold text-sm">N</span>
                </div>
                <span className="text-2xl font-bold text-white">NEXUS</span>
              </Link>

              <nav className="flex space-x-6">
                <Link href="/dashboard">
                  <Button variant="ghost" className="text-slate-400 hover:text-white">
                    Trading
                  </Button>
                </Link>
                <Button variant="ghost" className="text-blue-400">
                  Portfolio
                </Button>
                <Button variant="ghost" className="text-slate-400 hover:text-white">
                  Options
                </Button>
                <Button variant="ghost" className="text-slate-400 hover:text-white">
                  Analytics
                </Button>
              </nav>
            </div>

            <div className="flex items-center space-x-4">
              <Badge variant="outline" className="border-green-500 text-green-400">
                <div className="w-2 h-2 bg-green-400 rounded-full mr-2"></div>
                Base Network
              </Badge>
            </div>
          </div>
        </div>
      </header>

      <div className="container mx-auto px-4 py-6">
        {/* Portfolio Overview */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
          <Card className="bg-slate-900/50 border-slate-800">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-slate-400 mb-1">Total Portfolio Value</p>
                  <p className="text-3xl font-bold text-white">${portfolioData.totalValue.toLocaleString()}</p>
                </div>
                <DollarSign className="h-8 w-8 text-green-400" />
              </div>
            </CardContent>
          </Card>

          <Card className="bg-slate-900/50 border-slate-800">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-slate-400 mb-1">24h P&L</p>
                  <p className={`text-2xl font-bold ${portfolioData.pnl24h >= 0 ? "text-green-400" : "text-red-400"}`}>
                    {portfolioData.pnl24h >= 0 ? "+" : ""}${portfolioData.pnl24h.toLocaleString()}
                  </p>
                  <p className={`text-sm ${portfolioData.pnlPercent >= 0 ? "text-green-400" : "text-red-400"}`}>
                    ({portfolioData.pnlPercent >= 0 ? "+" : ""}
                    {portfolioData.pnlPercent}%)
                  </p>
                </div>
                {portfolioData.pnl24h >= 0 ? (
                  <TrendingUp className="h-8 w-8 text-green-400" />
                ) : (
                  <TrendingDown className="h-8 w-8 text-red-400" />
                )}
              </div>
            </CardContent>
          </Card>

          <Card className="bg-slate-900/50 border-slate-800">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-slate-400 mb-1">Margin Usage</p>
                  <p className="text-2xl font-bold text-white">
                    {(
                      (portfolioData.marginUsed / (portfolioData.marginUsed + portfolioData.marginAvailable)) *
                      100
                    ).toFixed(1)}
                    %
                  </p>
                  <p className="text-sm text-slate-400">
                    ${portfolioData.marginUsed.toLocaleString()} / $
                    {(portfolioData.marginUsed + portfolioData.marginAvailable).toLocaleString()}
                  </p>
                </div>
                <Shield className="h-8 w-8 text-orange-400" />
              </div>
            </CardContent>
          </Card>

          <Card className="bg-slate-900/50 border-slate-800">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-slate-400 mb-1">Active Positions</p>
                  <p className="text-2xl font-bold text-white">{portfolioData.positions}</p>
                  <p className="text-sm text-green-400">Cross-margined</p>
                </div>
                <Activity className="h-8 w-8 text-blue-400" />
              </div>
            </CardContent>
          </Card>
        </div>

        <div className="grid grid-cols-12 gap-6">
          {/* Asset Allocation */}
          <div className="col-span-12 lg:col-span-8">
            <Card className="bg-slate-900/50 border-slate-800">
              <CardHeader>
                <CardTitle className="text-white flex items-center">
                  <PieChart className="w-5 h-5 mr-2 text-blue-400" />
                  Asset Allocation
                </CardTitle>
                <CardDescription>Portfolio distribution across assets</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {assetAllocation.map((asset) => (
                    <div
                      key={asset.symbol}
                      className="flex items-center justify-between p-4 bg-slate-800/30 rounded-lg"
                    >
                      <div className="flex items-center space-x-4">
                        <div className={`w-4 h-4 rounded-full ${asset.color}`}></div>
                        <div>
                          <div className="font-semibold text-white">{asset.symbol}</div>
                          <div className="text-sm text-slate-400">${asset.value.toLocaleString()}</div>
                        </div>
                      </div>
                      <div className="text-right">
                        <div className="text-white font-semibold">{asset.percentage}%</div>
                        <div className={`text-sm ${asset.pnl >= 0 ? "text-green-400" : "text-red-400"}`}>
                          {asset.pnl >= 0 ? "+" : ""}${asset.pnl}
                        </div>
                      </div>
                      <div className="w-24">
                        <Progress value={asset.percentage} className="h-2" />
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Performance Metrics */}
          <div className="col-span-12 lg:col-span-4">
            <Card className="bg-slate-900/50 border-slate-800">
              <CardHeader>
                <CardTitle className="text-white flex items-center">
                  <BarChart3 className="w-5 h-5 mr-2 text-purple-400" />
                  Performance
                </CardTitle>
                <CardDescription>Risk-adjusted metrics</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="flex justify-between items-center">
                  <span className="text-slate-400">Sharpe Ratio</span>
                  <span className="text-green-400 font-bold">{performanceMetrics.sharpeRatio}</span>
                </div>

                <div className="flex justify-between items-center">
                  <span className="text-slate-400">Max Drawdown</span>
                  <span className="text-red-400">{performanceMetrics.maxDrawdown}%</span>
                </div>

                <div className="flex justify-between items-center">
                  <span className="text-slate-400">Win Rate</span>
                  <span className="text-blue-400">{performanceMetrics.winRate}%</span>
                </div>

                <div className="flex justify-between items-center">
                  <span className="text-slate-400">Avg Win</span>
                  <span className="text-green-400">${performanceMetrics.avgWin}</span>
                </div>

                <div className="flex justify-between items-center">
                  <span className="text-slate-400">Avg Loss</span>
                  <span className="text-red-400">${performanceMetrics.avgLoss}</span>
                </div>

                <div className="flex justify-between items-center">
                  <span className="text-slate-400">Total Trades</span>
                  <span className="text-white">{performanceMetrics.totalTrades}</span>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Cross-Margin Benefits */}
          <div className="col-span-12">
            <Card className="bg-gradient-to-r from-blue-900/30 to-purple-900/30 border-slate-700">
              <CardHeader>
                <CardTitle className="text-white flex items-center">
                  <Zap className="w-5 h-5 mr-2 text-yellow-400" />
                  Cross-Margin Efficiency
                </CardTitle>
                <CardDescription>Benefits of portfolio-level risk management</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
                  <div className="text-center">
                    <div className="text-3xl font-bold text-green-400 mb-2">32%</div>
                    <div className="text-slate-300">Margin Savings</div>
                    <div className="text-sm text-slate-400">vs isolated margin</div>
                  </div>
                  <div className="text-center">
                    <div className="text-3xl font-bold text-blue-400 mb-2">$14.4K</div>
                    <div className="text-slate-300">Additional Buying Power</div>
                    <div className="text-sm text-slate-400">freed up capital</div>
                  </div>
                  <div className="text-center">
                    <div className="text-3xl font-bold text-purple-400 mb-2">85%</div>
                    <div className="text-slate-300">Capital Efficiency</div>
                    <div className="text-sm text-slate-400">portfolio utilization</div>
                  </div>
                  <div className="text-center">
                    <div className="text-3xl font-bold text-orange-400 mb-2">2.3x</div>
                    <div className="text-slate-300">Leverage Multiplier</div>
                    <div className="text-sm text-slate-400">effective leverage</div>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* AI Portfolio Optimization */}
          <div className="col-span-12">
            <Card className="bg-slate-900/50 border-slate-800">
              <CardHeader>
                <CardTitle className="text-white flex items-center">
                  <Brain className="w-5 h-5 mr-2 text-pink-400" />
                  AI Portfolio Optimization
                </CardTitle>
                <CardDescription>Machine learning recommendations for your portfolio</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div className="space-y-4">
                    <h4 className="text-lg font-semibold text-white">Optimization Suggestions</h4>
                    <div className="space-y-3">
                      <div className="flex items-start space-x-3 p-3 bg-slate-800/30 rounded-lg">
                        <Target className="w-4 h-4 text-green-400 mt-1" />
                        <div>
                          <div className="text-white font-medium">Rebalance ETH/BTC Ratio</div>
                          <div className="text-sm text-slate-400">
                            Reduce correlation risk by adjusting to 40/35 split
                          </div>
                          <div className="text-xs text-green-400 mt-1">+$1,200 expected improvement</div>
                        </div>
                      </div>

                      <div className="flex items-start space-x-3 p-3 bg-slate-800/30 rounded-lg">
                        <Target className="w-4 h-4 text-blue-400 mt-1" />
                        <div>
                          <div className="text-white font-medium">Add DeFi Exposure</div>
                          <div className="text-sm text-slate-400">
                            Consider 5% allocation to DeFi tokens for diversification
                          </div>
                          <div className="text-xs text-blue-400 mt-1">Moderate risk, high reward potential</div>
                        </div>
                      </div>

                      <div className="flex items-start space-x-3 p-3 bg-slate-800/30 rounded-lg">
                        <Target className="w-4 h-4 text-yellow-400 mt-1" />
                        <div>
                          <div className="text-white font-medium">Hedge with Options</div>
                          <div className="text-sm text-slate-400">
                            Protect downside with put options on major positions
                          </div>
                          <div className="text-xs text-yellow-400 mt-1">Cost: $850, Protection: $12K</div>
                        </div>
                      </div>
                    </div>
                  </div>

                  <div className="space-y-4">
                    <h4 className="text-lg font-semibold text-white">Risk Analysis</h4>
                    <div className="space-y-3">
                      <div>
                        <div className="flex justify-between text-sm mb-1">
                          <span className="text-slate-400">Portfolio Beta</span>
                          <span className="text-white">1.23</span>
                        </div>
                        <Progress value={61.5} className="h-2" />
                      </div>

                      <div>
                        <div className="flex justify-between text-sm mb-1">
                          <span className="text-slate-400">Correlation Risk</span>
                          <span className="text-yellow-400">0.67</span>
                        </div>
                        <Progress value={67} className="h-2" />
                      </div>

                      <div>
                        <div className="flex justify-between text-sm mb-1">
                          <span className="text-slate-400">Volatility</span>
                          <span className="text-red-400">24.5%</span>
                        </div>
                        <Progress value={24.5} className="h-2" />
                      </div>

                      <div className="mt-4 p-3 bg-blue-900/20 rounded-lg border border-blue-500/30">
                        <div className="text-blue-400 font-medium mb-1">AI Recommendation</div>
                        <div className="text-sm text-slate-300">
                          Your portfolio shows strong performance but high correlation. Consider the suggested
                          rebalancing to improve risk-adjusted returns.
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        </div>
      </div>
    </div>
  )
}
