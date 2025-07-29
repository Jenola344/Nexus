"use client"

import { Card, CardContent } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { TrendingUp, TrendingDown, X } from "lucide-react"

interface Position {
  id: string
  symbol: string
  side: "long" | "short"
  size: number
  entryPrice: number
  markPrice: number
  pnl: number
  pnlPercent: number
  margin: number
  liquidationPrice: number
}

export function PositionsTable() {
  const positions: Position[] = [
    {
      id: "1",
      symbol: "ETH-PERP",
      side: "long",
      size: 5.2,
      entryPrice: 2420.5,
      markPrice: 2456.78,
      pnl: 188.66,
      pnlPercent: 1.5,
      margin: 2420.5,
      liquidationPrice: 1936.4,
    },
    {
      id: "2",
      symbol: "BTC-PERP",
      side: "short",
      size: -0.8,
      entryPrice: 43250.0,
      markPrice: 42890.25,
      pnl: 287.8,
      pnlPercent: 0.83,
      margin: 8650.0,
      liquidationPrice: 51900.0,
    },
    {
      id: "3",
      symbol: "SOL-PERP",
      side: "long",
      size: 150,
      entryPrice: 98.45,
      markPrice: 96.2,
      pnl: -337.5,
      pnlPercent: -2.29,
      margin: 2961.0,
      liquidationPrice: 78.76,
    },
  ]

  const handleClosePosition = (positionId: string) => {
    console.log("Closing position:", positionId)
  }

  return (
    <Card className="bg-slate-900/50 border-slate-800">
      <CardContent className="p-0">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="border-b border-slate-800">
                <th className="text-left p-4 text-sm font-semibold text-slate-300">Symbol</th>
                <th className="text-left p-4 text-sm font-semibold text-slate-300">Side</th>
                <th className="text-right p-4 text-sm font-semibold text-slate-300">Size</th>
                <th className="text-right p-4 text-sm font-semibold text-slate-300">Entry Price</th>
                <th className="text-right p-4 text-sm font-semibold text-slate-300">Mark Price</th>
                <th className="text-right p-4 text-sm font-semibold text-slate-300">PnL</th>
                <th className="text-right p-4 text-sm font-semibold text-slate-300">Margin</th>
                <th className="text-right p-4 text-sm font-semibold text-slate-300">Liq. Price</th>
                <th className="text-center p-4 text-sm font-semibold text-slate-300">Actions</th>
              </tr>
            </thead>
            <tbody>
              {positions.map((position) => (
                <tr key={position.id} className="border-b border-slate-800/50 hover:bg-slate-800/30">
                  <td className="p-4">
                    <div className="font-semibold text-white">{position.symbol}</div>
                  </td>
                  <td className="p-4">
                    <Badge
                      variant="outline"
                      className={
                        position.side === "long" ? "border-green-500 text-green-400" : "border-red-500 text-red-400"
                      }
                    >
                      {position.side === "long" ? (
                        <TrendingUp className="w-3 h-3 mr-1" />
                      ) : (
                        <TrendingDown className="w-3 h-3 mr-1" />
                      )}
                      {position.side.toUpperCase()}
                    </Badge>
                  </td>
                  <td className="p-4 text-right font-mono text-white">
                    {position.size > 0 ? "+" : ""}
                    {position.size}
                  </td>
                  <td className="p-4 text-right font-mono text-slate-300">${position.entryPrice.toLocaleString()}</td>
                  <td className="p-4 text-right font-mono text-white">${position.markPrice.toLocaleString()}</td>
                  <td className="p-4 text-right">
                    <div className={`font-mono ${position.pnl >= 0 ? "text-green-400" : "text-red-400"}`}>
                      {position.pnl >= 0 ? "+" : ""}${position.pnl.toFixed(2)}
                    </div>
                    <div className={`text-xs ${position.pnlPercent >= 0 ? "text-green-400" : "text-red-400"}`}>
                      ({position.pnlPercent >= 0 ? "+" : ""}
                      {position.pnlPercent.toFixed(2)}%)
                    </div>
                  </td>
                  <td className="p-4 text-right font-mono text-slate-300">${position.margin.toLocaleString()}</td>
                  <td className="p-4 text-right font-mono text-orange-400">
                    ${position.liquidationPrice.toLocaleString()}
                  </td>
                  <td className="p-4 text-center">
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() => handleClosePosition(position.id)}
                      className="border-red-500 text-red-400 hover:bg-red-500/10"
                    >
                      <X className="w-3 h-3 mr-1" />
                      Close
                    </Button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {positions.length === 0 && <div className="text-center py-12 text-slate-400">No open positions</div>}
      </CardContent>
    </Card>
  )
}
