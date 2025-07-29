"use client"

import { useState, useEffect } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { TrendingUp, TrendingDown, DollarSign, BarChart3, Activity, Shield, Brain } from "lucide-react"
import { TradingChart } from "../components/trading-chart"
import { OrderBook } from "../components/order-book"
import { PositionsTable } from "../components/positions-table"
import { RiskMetrics } from "../components/risk-metrics"
import { AIInsights } from "../components/ai-insights"
import { BasePairsWidget } from "../components/base-pairs-widget"
import { SepoliaTestnetWidget } from "../components/sepolia-testnet-widget"

export default function Dashboard() {
  const [selectedAsset, setSelectedAsset] = useState("ETH/USDbC")
  const [orderType, setOrderType] = useState("market")
  const [orderSide, setOrderSide] = useState("buy")
  const [orderSize, setOrderSize] = useState("")
  const [orderPrice, setOrderPrice] = useState("")

  // Mock real-time data
  const [marketData, setMarketData] = useState({
    price: 2456.78,
    change24h: 3.45,
    volume24h: 1234567890,
    openInterest: 987654321,
  })

  const [portfolioData, setPortfolioData] = useState({
    totalValue: 125000,
    pnl24h: 2340,
    marginUsed: 45000,
    marginAvailable: 80000,
    positions: 12,
  })

  useEffect(() => {
    // Simulate real-time price updates
    const interval = setInterval(() => {
      setMarketData((prev) => ({
        ...prev,
        price: prev.price + (Math.random() - 0.5) * 10,
        change24h: prev.change24h + (Math.random() - 0.5) * 0.5,
      }))
    }, 2000)

    return () => clearInterval(interval)
  }, [])

  const handlePlaceOrder = () => {
    // Mock order placement
    console.log("Placing order:", { orderType, orderSide, orderSize, orderPrice })
  }

  return (
    <div className="min-h-screen bg-slate-950">
      {/* Header */}
      <header className="border-b border-slate-800 bg-slate-900/50 backdrop-blur-sm">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-6">
              <div className="flex items-center space-x-2">
                <div className="h-8 w-8 rounded-lg bg-gradient-to-r from-blue-500 to-purple-600 flex items-center justify-center">
                  <span className="text-white font-bold text-sm">N</span>
                </div>
                <span className="text-2xl font-bold text-white">NEXUS</span>
              </div>

              <nav className="flex space-x-6">
                <Button variant="ghost" className="text-blue-400">
                  Trading
                </Button>
                <Button variant="ghost" className="text-slate-400 hover:text-white">
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
              <Badge variant="outline" className="border-blue-500 text-blue-400">
                <div className="w-2 h-2 bg-blue-400 rounded-full mr-2 animate-pulse"></div>
                Smart Contracts Active
              </Badge>
              <div className="text-right">
                <div className="text-sm text-slate-400">Portfolio Value</div>
                <div className="text-lg font-bold text-white">${portfolioData.totalValue.toLocaleString()}</div>
              </div>
            </div>
          </div>
        </div>
      </header>

      <div className="container mx-auto px-4 py-6">
        <div className="grid grid-cols-12 gap-6">
          {/* Market Overview */}
          <div className="col-span-12">
            <div className="grid grid-cols-1 md:grid-cols-5 gap-4 mb-6">
              <Card className="bg-slate-900/50 border-slate-800">
                <CardContent className="p-4">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-sm text-slate-400">ETH Price</p>
                      <p className="text-2xl font-bold text-white">${marketData.price.toFixed(2)}</p>
                    </div>
                    <div
                      className={`flex items-center ${marketData.change24h >= 0 ? "text-green-400" : "text-red-400"}`}
                    >
                      {marketData.change24h >= 0 ? (
                        <TrendingUp className="h-4 w-4 mr-1" />
                      ) : (
                        <TrendingDown className="h-4 w-4 mr-1" />
                      )}
                      {Math.abs(marketData.change24h).toFixed(2)}%
                    </div>
                  </div>
                </CardContent>
              </Card>

              <Card className="bg-slate-900/50 border-slate-800">
                <CardContent className="p-4">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-sm text-slate-400">24h Volume</p>
                      <p className="text-xl font-bold text-white">${(marketData.volume24h / 1e9).toFixed(2)}B</p>
                    </div>
                    <BarChart3 className="h-6 w-6 text-blue-400" />
                  </div>
                </CardContent>
              </Card>

              <Card className="bg-slate-900/50 border-slate-800">
                <CardContent className="p-4">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-sm text-slate-400">Open Interest</p>
                      <p className="text-xl font-bold text-white">${(marketData.openInterest / 1e6).toFixed(0)}M</p>
                    </div>
                    <Activity className="h-6 w-6 text-purple-400" />
                  </div>
                </CardContent>
              </Card>

              <Card className="bg-slate-900/50 border-slate-800">
                <CardContent className="p-4">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-sm text-slate-400">24h P&L</p>
                      <p
                        className={`text-xl font-bold ${portfolioData.pnl24h >= 0 ? "text-green-400" : "text-red-400"}`}
                      >
                        ${portfolioData.pnl24h >= 0 ? "+" : ""}${portfolioData.pnl24h.toLocaleString()}
                      </p>
                    </div>
                    <DollarSign className="h-6 w-6 text-green-400" />
                  </div>
                </CardContent>
              </Card>

              <Card className="bg-slate-900/50 border-slate-800">
                <CardContent className="p-4">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-sm text-slate-400">Margin Used</p>
                      <p className="text-xl font-bold text-white">
                        {(
                          (portfolioData.marginUsed / (portfolioData.marginUsed + portfolioData.marginAvailable)) *
                          100
                        ).toFixed(1)}
                        %
                      </p>
                    </div>
                    <Shield className="h-6 w-6 text-orange-400" />
                  </div>
                </CardContent>
              </Card>
            </div>
          </div>

          {/* Trading Chart */}
          <div className="col-span-12 lg:col-span-8">
            <Card className="bg-slate-900/50 border-slate-800 h-[600px]">
              <CardHeader className="pb-4">
                <div className="flex items-center justify-between">
                  <CardTitle className="text-white">Price Chart</CardTitle>
                  <div className="flex items-center space-x-2">
                    <Select value={selectedAsset} onValueChange={setSelectedAsset}>
                      <SelectTrigger className="w-32 bg-slate-800 border-slate-700">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="ETH-PERP">ETH-PERP</SelectItem>
                        <SelectItem value="BTC-PERP">BTC-PERP</SelectItem>
                        <SelectItem value="SOL-PERP">SOL-PERP</SelectItem>
                        <SelectItem value="ETH/USDbC">ETH/USDbC</SelectItem>
                        <SelectItem value="cbETH/ETH">cbETH/ETH</SelectItem>
                        <SelectItem value="DAI/USDbC">DAI/USDbC</SelectItem>
                        <SelectItem value="AERO/ETH">AERO/ETH</SelectItem>
                        <SelectItem value="BASE/ETH">BASE/ETH</SelectItem>
                        <SelectItem value="BASE/ETH(Sepolia)">BASE/ETH(Sepolia)</SelectItem>
                      </SelectContent>
                    </Select>
                    <Badge variant="outline" className="border-blue-500 text-blue-400">
                      <Brain className="w-3 h-3 mr-1" />
                      AI Active
                    </Badge>
                  </div>
                </div>
              </CardHeader>
              <CardContent className="p-0 h-[500px]">
                <TradingChart />
              </CardContent>
            </Card>
          </div>

          {/* Order Book & Trading Panel */}
          <div className="col-span-12 lg:col-span-4 space-y-6">
            {/* Order Book */}
            <Card className="bg-slate-900/50 border-slate-800">
              <CardHeader className="pb-4">
                <CardTitle className="text-white text-lg">Order Book</CardTitle>
              </CardHeader>
              <CardContent className="p-0">
                <OrderBook />
              </CardContent>
            </Card>

            {/* Trading Panel */}
            <Card className="bg-slate-900/50 border-slate-800">
              <CardHeader className="pb-4">
                <CardTitle className="text-white text-lg">Place Order</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <Tabs value={orderSide} onValueChange={setOrderSide}>
                  <TabsList className="grid w-full grid-cols-2 bg-slate-800">
                    <TabsTrigger value="buy" className="data-[state=active]:bg-green-600">
                      Buy
                    </TabsTrigger>
                    <TabsTrigger value="sell" className="data-[state=active]:bg-red-600">
                      Sell
                    </TabsTrigger>
                  </TabsList>
                </Tabs>

                <div className="space-y-3">
                  <div>
                    <Label className="text-slate-300">Order Type</Label>
                    <Select value={orderType} onValueChange={setOrderType}>
                      <SelectTrigger className="bg-slate-800 border-slate-700">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="market">Market</SelectItem>
                        <SelectItem value="limit">Limit</SelectItem>
                        <SelectItem value="stop">Stop</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>

                  <div>
                    <Label className="text-slate-300">Size (ETH)</Label>
                    <Input
                      value={orderSize}
                      onChange={(e) => setOrderSize(e.target.value)}
                      placeholder="0.00"
                      className="bg-slate-800 border-slate-700"
                    />
                  </div>

                  {orderType === "limit" && (
                    <div>
                      <Label className="text-slate-300">Price (USD)</Label>
                      <Input
                        value={orderPrice}
                        onChange={(e) => setOrderPrice(e.target.value)}
                        placeholder="0.00"
                        className="bg-slate-800 border-slate-700"
                      />
                    </div>
                  )}

                  <Button
                    onClick={handlePlaceOrder}
                    className={`w-full ${orderSide === "buy" ? "bg-green-600 hover:bg-green-700" : "bg-red-600 hover:bg-red-700"}`}
                  >
                    {orderSide === "buy" ? "Buy" : "Sell"} {selectedAsset}
                  </Button>
                  <div className="text-xs text-slate-400 mt-2 flex items-center">
                    <div className="w-1 h-1 bg-green-400 rounded-full mr-2"></div>
                    Connected to NEXUS Cross-Margin Contract
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Bottom Section */}
          <div className="col-span-12">
            <Tabs defaultValue="positions" className="space-y-4">
              <TabsList className="bg-slate-800">
                <TabsTrigger value="positions">Positions</TabsTrigger>
                <TabsTrigger value="orders">Open Orders</TabsTrigger>
                <TabsTrigger value="history">Trade History</TabsTrigger>
                <TabsTrigger value="risk">Risk Management</TabsTrigger>
                <TabsTrigger value="ai">AI Insights</TabsTrigger>
                <TabsTrigger value="pairs">Base Pairs</TabsTrigger>
                <TabsTrigger value="sepolia">Sepolia Testnet</TabsTrigger>
              </TabsList>

              <TabsContent value="positions">
                <PositionsTable />
              </TabsContent>

              <TabsContent value="orders">
                <Card className="bg-slate-900/50 border-slate-800">
                  <CardContent className="p-6">
                    <div className="text-center text-slate-400 py-8">No open orders</div>
                  </CardContent>
                </Card>
              </TabsContent>

              <TabsContent value="history">
                <Card className="bg-slate-900/50 border-slate-800">
                  <CardContent className="p-6">
                    <div className="text-center text-slate-400 py-8">Trade history will appear here</div>
                  </CardContent>
                </Card>
              </TabsContent>

              <TabsContent value="risk">
                <RiskMetrics />
              </TabsContent>

              <TabsContent value="ai">
                <AIInsights />
              </TabsContent>

              <TabsContent value="pairs">
                <BasePairsWidget />
              </TabsContent>

              <TabsContent value="sepolia">
                <SepoliaTestnetWidget />
              </TabsContent>
            </Tabs>
          </div>
        </div>
      </div>
    </div>
  )
}
