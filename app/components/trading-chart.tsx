"use client"

import { useEffect, useRef, useState } from "react"

export function TradingChart() {
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const [priceData, setPriceData] = useState<number[]>([])

  useEffect(() => {
    // Generate mock price data
    const generatePriceData = () => {
      const data = []
      let price = 2450
      for (let i = 0; i < 100; i++) {
        price += (Math.random() - 0.5) * 20
        data.push(price)
      }
      return data
    }

    setPriceData(generatePriceData())

    // Update price data periodically
    const interval = setInterval(() => {
      setPriceData((prev) => {
        const newData = [...prev.slice(1)]
        const lastPrice = newData[newData.length - 1] || 2450
        newData.push(lastPrice + (Math.random() - 0.5) * 10)
        return newData
      })
    }, 1000)

    return () => clearInterval(interval)
  }, [])

  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas || priceData.length === 0) return

    const ctx = canvas.getContext("2d")
    if (!ctx) return

    const { width, height } = canvas
    ctx.clearRect(0, 0, width, height)

    // Set up chart styling
    ctx.strokeStyle = "#3b82f6"
    ctx.lineWidth = 2
    ctx.fillStyle = "rgba(59, 130, 246, 0.1)"

    // Calculate price range
    const minPrice = Math.min(...priceData)
    const maxPrice = Math.max(...priceData)
    const priceRange = maxPrice - minPrice

    // Draw price line
    ctx.beginPath()
    priceData.forEach((price, index) => {
      const x = (index / (priceData.length - 1)) * width
      const y = height - ((price - minPrice) / priceRange) * height

      if (index === 0) {
        ctx.moveTo(x, y)
      } else {
        ctx.lineTo(x, y)
      }
    })
    ctx.stroke()

    // Fill area under curve
    ctx.lineTo(width, height)
    ctx.lineTo(0, height)
    ctx.closePath()
    ctx.fill()

    // Draw grid lines
    ctx.strokeStyle = "rgba(148, 163, 184, 0.1)"
    ctx.lineWidth = 1

    // Horizontal grid lines
    for (let i = 0; i <= 5; i++) {
      const y = (i / 5) * height
      ctx.beginPath()
      ctx.moveTo(0, y)
      ctx.lineTo(width, y)
      ctx.stroke()
    }

    // Vertical grid lines
    for (let i = 0; i <= 10; i++) {
      const x = (i / 10) * width
      ctx.beginPath()
      ctx.moveTo(x, 0)
      ctx.lineTo(x, height)
      ctx.stroke()
    }

    // Draw price labels
    ctx.fillStyle = "#94a3b8"
    ctx.font = "12px monospace"
    ctx.textAlign = "right"

    for (let i = 0; i <= 5; i++) {
      const price = minPrice + (priceRange * (5 - i)) / 5
      const y = (i / 5) * height + 4
      ctx.fillText(`$${price.toFixed(0)}`, width - 10, y)
    }
  }, [priceData])

  return (
    <div className="relative w-full h-full bg-slate-950 rounded-lg overflow-hidden">
      <canvas ref={canvasRef} width={800} height={500} className="w-full h-full" />

      {/* Trading indicators overlay */}
      <div className="absolute top-4 left-4 space-y-2">
        <div className="flex items-center space-x-4 text-sm">
          <span className="text-slate-400">RSI:</span>
          <span className="text-green-400">65.4</span>
          <span className="text-slate-400">MACD:</span>
          <span className="text-red-400">-12.3</span>
          <span className="text-slate-400">Vol:</span>
          <span className="text-blue-400">1.2M</span>
        </div>
      </div>

      {/* AI prediction overlay */}
      <div className="absolute top-4 right-4 bg-slate-800/80 rounded-lg p-3 backdrop-blur-sm">
        <div className="flex items-center space-x-2 text-sm">
          <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse"></div>
          <span className="text-slate-300">AI Prediction:</span>
          <span className="text-green-400 font-semibold">+2.3% (4h)</span>
        </div>
      </div>
    </div>
  )
}
