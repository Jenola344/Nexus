"use client"

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Progress } from "@/components/ui/progress"
import { Badge } from "@/components/ui/badge"
import { AlertTriangle, Shield, TrendingUp, Target } from "lucide-react"

export function RiskMetrics() {
  const riskData = {
    portfolioValue: 125000,
    totalMargin: 45000,
    availableMargin: 80000,
    marginRatio: 36,
    liquidationRisk: "Low",
    var95: 2340,
    sharpeRatio: 1.85,
    maxDrawdown: 8.5,
    correlationRisk: 0.65,
    concentrationRisk: "Medium",
  }

  const getRiskColor = (risk: string) => {
    switch (risk.toLowerCase()) {
      case "low":
        return "text-green-400 border-green-500"
      case "medium":
        return "text-yellow-400 border-yellow-500"
      case "high":
        return "text-red-400 border-red-500"
      default:
        return "text-slate-400 border-slate-500"
    }
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      {/* Portfolio Risk Overview */}
      <Card className="bg-slate-900/50 border-slate-800">
        <CardHeader>
          <CardTitle className="text-white flex items-center">
            <Shield className="w-5 h-5 mr-2 text-blue-400" />
            Portfolio Risk
          </CardTitle>
          <CardDescription>Overall risk assessment</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div>
            <div className="flex justify-between text-sm mb-2">
              <span className="text-slate-400">Margin Usage</span>
              <span className="text-white">{riskData.marginRatio}%</span>
            </div>
            <Progress value={riskData.marginRatio} className="h-2" />
          </div>

          <div className="flex justify-between items-center">
            <span className="text-slate-400">Liquidation Risk</span>
            <Badge variant="outline" className={getRiskColor(riskData.liquidationRisk)}>
              {riskData.liquidationRisk}
            </Badge>
          </div>

          <div className="flex justify-between items-center">
            <span className="text-slate-400">Available Margin</span>
            <span className="text-white font-mono">${riskData.availableMargin.toLocaleString()}</span>
          </div>
        </CardContent>
      </Card>

      {/* Value at Risk */}
      <Card className="bg-slate-900/50 border-slate-800">
        <CardHeader>
          <CardTitle className="text-white flex items-center">
            <AlertTriangle className="w-5 h-5 mr-2 text-orange-400" />
            Value at Risk
          </CardTitle>
          <CardDescription>95% confidence interval</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="text-center">
            <div className="text-3xl font-bold text-orange-400 mb-2">${riskData.var95.toLocaleString()}</div>
            <div className="text-sm text-slate-400">Maximum expected loss (24h)</div>
          </div>

          <div className="space-y-2">
            <div className="flex justify-between">
              <span className="text-slate-400">As % of Portfolio</span>
              <span className="text-white">{((riskData.var95 / riskData.portfolioValue) * 100).toFixed(2)}%</span>
            </div>
            <div className="flex justify-between">
              <span className="text-slate-400">Confidence Level</span>
              <span className="text-white">95%</span>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Performance Metrics */}
      <Card className="bg-slate-900/50 border-slate-800">
        <CardHeader>
          <CardTitle className="text-white flex items-center">
            <TrendingUp className="w-5 h-5 mr-2 text-green-400" />
            Performance
          </CardTitle>
          <CardDescription>Risk-adjusted returns</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex justify-between items-center">
            <span className="text-slate-400">Sharpe Ratio</span>
            <span className="text-green-400 font-bold">{riskData.sharpeRatio}</span>
          </div>

          <div className="flex justify-between items-center">
            <span className="text-slate-400">Max Drawdown</span>
            <span className="text-red-400">{riskData.maxDrawdown}%</span>
          </div>

          <div className="flex justify-between items-center">
            <span className="text-slate-400">Correlation Risk</span>
            <span className="text-yellow-400">{riskData.correlationRisk}</span>
          </div>
        </CardContent>
      </Card>

      {/* Concentration Risk */}
      <Card className="bg-slate-900/50 border-slate-800">
        <CardHeader>
          <CardTitle className="text-white flex items-center">
            <Target className="w-5 h-5 mr-2 text-purple-400" />
            Concentration
          </CardTitle>
          <CardDescription>Position concentration analysis</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex justify-between items-center">
            <span className="text-slate-400">Concentration Risk</span>
            <Badge variant="outline" className={getRiskColor(riskData.concentrationRisk)}>
              {riskData.concentrationRisk}
            </Badge>
          </div>

          <div className="space-y-2">
            <div className="flex justify-between text-sm">
              <span className="text-slate-400">ETH Exposure</span>
              <span className="text-white">45%</span>
            </div>
            <Progress value={45} className="h-1" />

            <div className="flex justify-between text-sm">
              <span className="text-slate-400">BTC Exposure</span>
              <span className="text-white">30%</span>
            </div>
            <Progress value={30} className="h-1" />

            <div className="flex justify-between text-sm">
              <span className="text-slate-400">Other Assets</span>
              <span className="text-white">25%</span>
            </div>
            <Progress value={25} className="h-1" />
          </div>
        </CardContent>
      </Card>

      {/* Cross-Margin Benefits */}
      <Card className="bg-slate-900/50 border-slate-800 md:col-span-2">
        <CardHeader>
          <CardTitle className="text-white">Cross-Margin Efficiency</CardTitle>
          <CardDescription>Benefits of portfolio-level margining</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="text-center">
              <div className="text-2xl font-bold text-green-400 mb-1">32%</div>
              <div className="text-sm text-slate-400">Margin Savings</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-blue-400 mb-1">$14.4K</div>
              <div className="text-sm text-slate-400">Additional Buying Power</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-purple-400 mb-1">85%</div>
              <div className="text-sm text-slate-400">Capital Efficiency</div>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
