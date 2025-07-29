"use client"

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Brain, TrendingUp, AlertTriangle, Target, Zap, Eye } from "lucide-react"

export function AIInsights() {
  const insights = [
    {
      id: 1,
      type: "opportunity",
      title: "Arbitrage Opportunity Detected",
      description: "ETH-PERP showing 0.15% premium vs spot. Consider short position.",
      confidence: 87,
      timeframe: "2-4 hours",
      impact: "Medium",
      action: "Consider shorting ETH-PERP",
    },
    {
      id: 2,
      type: "risk",
      title: "Correlation Risk Alert",
      description: "Your ETH and BTC positions showing high correlation (0.89). Consider diversification.",
      confidence: 92,
      timeframe: "Ongoing",
      impact: "High",
      action: "Reduce position correlation",
    },
    {
      id: 3,
      type: "market",
      title: "Volatility Spike Expected",
      description: "Options flow suggests 15% volatility increase in next 24h. Adjust position sizing.",
      confidence: 78,
      timeframe: "24 hours",
      impact: "Medium",
      action: "Reduce leverage",
    },
    {
      id: 4,
      type: "optimization",
      title: "Margin Efficiency Improvement",
      description: "Rebalancing positions could free up $3.2K in margin while maintaining exposure.",
      confidence: 95,
      timeframe: "Immediate",
      impact: "Low",
      action: "Optimize positions",
    },
  ]

  const getInsightIcon = (type: string) => {
    switch (type) {
      case "opportunity":
        return <TrendingUp className="w-4 h-4 text-green-400" />
      case "risk":
        return <AlertTriangle className="w-4 h-4 text-red-400" />
      case "market":
        return <Eye className="w-4 h-4 text-blue-400" />
      case "optimization":
        return <Target className="w-4 h-4 text-purple-400" />
      default:
        return <Brain className="w-4 h-4 text-slate-400" />
    }
  }

  const getConfidenceColor = (confidence: number) => {
    if (confidence >= 90) return "text-green-400 border-green-500"
    if (confidence >= 70) return "text-yellow-400 border-yellow-500"
    return "text-red-400 border-red-500"
  }

  const getImpactColor = (impact: string) => {
    switch (impact.toLowerCase()) {
      case "high":
        return "text-red-400 border-red-500"
      case "medium":
        return "text-yellow-400 border-yellow-500"
      case "low":
        return "text-green-400 border-green-500"
      default:
        return "text-slate-400 border-slate-500"
    }
  }

  return (
    <div className="space-y-6">
      {/* AI Status */}
      <Card className="bg-gradient-to-r from-blue-900/50 to-purple-900/50 border-slate-700">
        <CardContent className="p-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <div className="p-2 bg-blue-500/20 rounded-lg">
                <Brain className="w-6 h-6 text-blue-400" />
              </div>
              <div>
                <h3 className="text-lg font-semibold text-white">AI Risk Engine</h3>
                <p className="text-slate-300">Analyzing 1,247 data points across 12 markets</p>
              </div>
            </div>
            <div className="flex items-center space-x-2">
              <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse"></div>
              <span className="text-green-400 text-sm font-medium">Active</span>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Insights Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {insights.map((insight) => (
          <Card key={insight.id} className="bg-slate-900/50 border-slate-800">
            <CardHeader className="pb-3">
              <div className="flex items-start justify-between">
                <div className="flex items-center space-x-2">
                  {getInsightIcon(insight.type)}
                  <CardTitle className="text-white text-lg">{insight.title}</CardTitle>
                </div>
                <Badge variant="outline" className={getConfidenceColor(insight.confidence)}>
                  {insight.confidence}% confidence
                </Badge>
              </div>
            </CardHeader>
            <CardContent className="space-y-4">
              <p className="text-slate-300">{insight.description}</p>

              <div className="flex items-center justify-between text-sm">
                <div className="flex items-center space-x-4">
                  <div>
                    <span className="text-slate-400">Timeframe: </span>
                    <span className="text-white">{insight.timeframe}</span>
                  </div>
                  <Badge variant="outline" className={getImpactColor(insight.impact)}>
                    {insight.impact} Impact
                  </Badge>
                </div>
              </div>

              <div className="flex items-center justify-between pt-2">
                <div className="text-sm">
                  <span className="text-slate-400">Suggested Action: </span>
                  <span className="text-blue-400">{insight.action}</span>
                </div>
                <Button
                  size="sm"
                  variant="outline"
                  className="border-blue-500 text-blue-400 hover:bg-blue-500/10 bg-transparent"
                >
                  <Zap className="w-3 h-3 mr-1" />
                  Execute
                </Button>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* AI Performance Metrics */}
      <Card className="bg-slate-900/50 border-slate-800">
        <CardHeader>
          <CardTitle className="text-white">AI Performance Metrics</CardTitle>
          <CardDescription>Track record of AI recommendations</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
            <div className="text-center">
              <div className="text-2xl font-bold text-green-400 mb-1">73.2%</div>
              <div className="text-sm text-slate-400">Prediction Accuracy</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-blue-400 mb-1">+12.4%</div>
              <div className="text-sm text-slate-400">Alpha Generated</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-purple-400 mb-1">1,247</div>
              <div className="text-sm text-slate-400">Signals Generated</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-orange-400 mb-1">2.3x</div>
              <div className="text-sm text-slate-400">Risk-Adjusted Return</div>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
