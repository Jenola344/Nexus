"use client"

import { useEffect, useState } from "react"

interface OrderBookEntry {
  price: number
  size: number
  total: number
}

export function OrderBook() {
  const [bids, setBids] = useState<OrderBookEntry[]>([])
  const [asks, setAsks] = useState<OrderBookEntry[]>([])
  const [spread, setSpread] = useState(0)

  useEffect(() => {
    // Generate mock order book data
    const generateOrderBook = () => {
      const basePrice = 2456.78
      const newBids: OrderBookEntry[] = []
      const newAsks: OrderBookEntry[] = []

      let total = 0
      for (let i = 0; i < 10; i++) {
        const price = basePrice - (i + 1) * 0.5
        const size = Math.random() * 10 + 1
        total += size
        newBids.push({ price, size, total })
      }

      total = 0
      for (let i = 0; i < 10; i++) {
        const price = basePrice + (i + 1) * 0.5
        const size = Math.random() * 10 + 1
        total += size
        newAsks.push({ price, size, total })
      }

      setBids(newBids)
      setAsks(newAsks.reverse())
      setSpread(newAsks[0]?.price - newBids[0]?.price || 0)
    }

    generateOrderBook()
    const interval = setInterval(generateOrderBook, 2000)
    return () => clearInterval(interval)
  }, [])

  const maxTotal = Math.max(Math.max(...bids.map((b) => b.total), 0), Math.max(...asks.map((a) => a.total), 0))

  return (
    <div className="h-96 overflow-hidden">
      {/* Asks (Sell Orders) */}
      <div className="space-y-1 mb-2">
        {asks.slice(0, 8).map((ask, index) => (
          <div key={index} className="relative flex justify-between items-center px-3 py-1 text-xs">
            <div className="absolute inset-0 bg-red-500/10" style={{ width: `${(ask.total / maxTotal) * 100}%` }} />
            <span className="text-red-400 font-mono">{ask.price.toFixed(2)}</span>
            <span className="text-slate-300 font-mono">{ask.size.toFixed(3)}</span>
            <span className="text-slate-400 font-mono">{ask.total.toFixed(2)}</span>
          </div>
        ))}
      </div>

      {/* Spread */}
      <div className="border-t border-b border-slate-700 py-2 px-3 text-center">
        <div className="text-xs text-slate-400">Spread</div>
        <div className="text-sm font-mono text-white">${spread.toFixed(2)}</div>
      </div>

      {/* Bids (Buy Orders) */}
      <div className="space-y-1 mt-2">
        {bids.slice(0, 8).map((bid, index) => (
          <div key={index} className="relative flex justify-between items-center px-3 py-1 text-xs">
            <div className="absolute inset-0 bg-green-500/10" style={{ width: `${(bid.total / maxTotal) * 100}%` }} />
            <span className="text-green-400 font-mono">{bid.price.toFixed(2)}</span>
            <span className="text-slate-300 font-mono">{bid.size.toFixed(3)}</span>
            <span className="text-slate-400 font-mono">{bid.total.toFixed(2)}</span>
          </div>
        ))}
      </div>

      {/* Header */}
      <div className="absolute top-0 left-0 right-0 bg-slate-900 border-b border-slate-700 px-3 py-2">
        <div className="flex justify-between text-xs text-slate-400 font-semibold">
          <span>Price (USD)</span>
          <span>Size (ETH)</span>
          <span>Total</span>
        </div>
      </div>
    </div>
  )
}
