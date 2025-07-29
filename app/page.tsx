"use client"

import { useState } from "react"
import Link from "next/link"
import { ArrowRight, BarChart3, Shield, Zap, TrendingUp, Users, Brain, Globe } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"

export default function LandingPage() {
  const [isConnected, setIsConnected] = useState(false)

  const connectWallet = async () => {
    // Mock wallet connection
    setIsConnected(true)
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-blue-900 to-slate-900">
      {/* Navigation */}
      <nav className="border-b border-slate-800 bg-slate-900/50 backdrop-blur-sm">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-2">
              <div className="h-8 w-8 rounded-lg bg-gradient-to-r from-blue-500 to-purple-600 flex items-center justify-center">
                <span className="text-white font-bold text-sm">N</span>
              </div>
              <span className="text-2xl font-bold text-white">NEXUS</span>
              <Badge variant="secondary" className="ml-2">
                Base Network
              </Badge>
            </div>
            <div className="flex items-center space-x-4">
              <Link href="/docs" className="text-slate-300 hover:text-white transition-colors">
                Docs
              </Link>
              <Link href="/analytics" className="text-slate-300 hover:text-white transition-colors">
                Analytics
              </Link>
              {isConnected ? (
                <Link href="/dashboard">
                  <Button className="bg-gradient-to-r from-blue-500 to-purple-600 hover:from-blue-600 hover:to-purple-700">
                    Launch App
                  </Button>
                </Link>
              ) : (
                <Button
                  onClick={connectWallet}
                  className="bg-gradient-to-r from-blue-500 to-purple-600 hover:from-blue-600 hover:to-purple-700"
                >
                  Connect Wallet
                </Button>
              )}
            </div>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="container mx-auto px-4 py-20">
        <div className="text-center max-w-4xl mx-auto">
          <h1 className="text-6xl font-bold text-white mb-6">
            The Future of
            <span className="bg-gradient-to-r from-blue-400 to-purple-400 bg-clip-text text-transparent">
              {" "}
              Derivatives Trading
            </span>
          </h1>
          <p className="text-xl text-slate-300 mb-8 leading-relaxed">
            NEXUS brings institutional-grade derivatives trading to DeFi with cross-margining, automated market making,
            and AI-powered risk management on Base blockchain.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Link href="/dashboard">
              <Button
                size="lg"
                className="bg-gradient-to-r from-blue-500 to-purple-600 hover:from-blue-600 hover:to-purple-700"
              >
                Start Trading <ArrowRight className="ml-2 h-4 w-4" />
              </Button>
            </Link>
            <Button
              size="lg"
              variant="outline"
              className="border-slate-600 text-slate-300 hover:bg-slate-800 bg-transparent"
            >
              View Documentation
            </Button>
          </div>
        </div>
      </section>

      {/* Features Grid */}
      <section className="container mx-auto px-4 py-20">
        <div className="text-center mb-16">
          <h2 className="text-4xl font-bold text-white mb-4">Revolutionary Features</h2>
          <p className="text-slate-300 text-lg">Setting new standards for DeFi derivatives trading</p>
        </div>

        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
          <Card className="bg-slate-800/50 border-slate-700 hover:bg-slate-800/70 transition-colors">
            <CardHeader>
              <BarChart3 className="h-12 w-12 text-blue-400 mb-4" />
              <CardTitle className="text-white">Cross-Asset Margining</CardTitle>
              <CardDescription className="text-slate-300">
                First-in-DeFi portfolio-level risk management powered by advanced smart contracts with automated
                liquidations
              </CardDescription>
            </CardHeader>
          </Card>

          <Card className="bg-slate-800/50 border-slate-700 hover:bg-slate-800/70 transition-colors">
            <CardHeader>
              <Zap className="h-12 w-12 text-purple-400 mb-4" />
              <CardTitle className="text-white">Automated Market Making</CardTitle>
              <CardDescription className="text-slate-300">
                AI-powered options market making with dynamic pricing and liquidity provision
              </CardDescription>
            </CardHeader>
          </Card>

          <Card className="bg-slate-800/50 border-slate-700 hover:bg-slate-800/70 transition-colors">
            <CardHeader>
              <Shield className="h-12 w-12 text-green-400 mb-4" />
              <CardTitle className="text-white">Institutional Security</CardTitle>
              <CardDescription className="text-slate-300">
                Bank-grade security with automated liquidations and risk management
              </CardDescription>
            </CardHeader>
          </Card>

          <Card className="bg-slate-800/50 border-slate-700 hover:bg-slate-800/70 transition-colors">
            <CardHeader>
              <TrendingUp className="h-12 w-12 text-orange-400 mb-4" />
              <CardTitle className="text-white">Synthetic Assets</CardTitle>
              <CardDescription className="text-slate-300">
                Community-created synthetic assets with automated pricing and settlement
              </CardDescription>
            </CardHeader>
          </Card>

          <Card className="bg-slate-800/50 border-slate-700 hover:bg-slate-800/70 transition-colors">
            <CardHeader>
              <Brain className="h-12 w-12 text-pink-400 mb-4" />
              <CardTitle className="text-white">AI-Powered Insights</CardTitle>
              <CardDescription className="text-slate-300">
                Machine learning algorithms for risk assessment and trading recommendations
              </CardDescription>
            </CardHeader>
          </Card>

          <Card className="bg-slate-800/50 border-slate-700 hover:bg-slate-800/70 transition-colors">
            <CardHeader>
              <Users className="h-12 w-12 text-cyan-400 mb-4" />
              <CardTitle className="text-white">Social Trading</CardTitle>
              <CardDescription className="text-slate-300">
                Follow top traders, share strategies, and build trading communities
              </CardDescription>
            </CardHeader>
          </Card>
        </div>
      </section>

      {/* Stats Section */}
      <section className="container mx-auto px-4 py-20">
        <div className="grid md:grid-cols-4 gap-8 text-center">
          <div>
            <div className="text-4xl font-bold text-blue-400 mb-2">$2.5B+</div>
            <div className="text-slate-300">Total Volume Traded</div>
          </div>
          <div>
            <div className="text-4xl font-bold text-purple-400 mb-2">50K+</div>
            <div className="text-slate-300">Active Traders</div>
          </div>
          <div>
            <div className="text-4xl font-bold text-green-400 mb-2">99.9%</div>
            <div className="text-slate-300">Uptime</div>
          </div>
          <div>
            <div className="text-4xl font-bold text-orange-400 mb-2">0.01%</div>
            <div className="text-slate-300">Trading Fees</div>
          </div>
        </div>
      </section>

      {/* Smart Contract Architecture */}
      <section className="container mx-auto px-4 py-20">
        <div className="text-center mb-16">
          <h2 className="text-4xl font-bold text-white mb-4">Institutional-Grade Smart Contracts</h2>
          <p className="text-slate-300 text-lg">Built on Base blockchain for maximum security and efficiency</p>
        </div>

        <div className="grid md:grid-cols-3 gap-8">
          <Card className="bg-slate-800/50 border-slate-700">
            <CardContent className="p-6 text-center">
              <Shield className="h-12 w-12 text-green-400 mx-auto mb-4" />
              <h3 className="text-xl font-bold text-white mb-2">Cross-Margin Engine</h3>
              <p className="text-slate-300">
                Advanced portfolio-level risk calculations with real-time liquidation protection
              </p>
            </CardContent>
          </Card>

          <Card className="bg-slate-800/50 border-slate-700">
            <CardContent className="p-6 text-center">
              <Zap className="h-12 w-12 text-blue-400 mx-auto mb-4" />
              <h3 className="text-xl font-bold text-white mb-2">Automated Market Making</h3>
              <p className="text-slate-300">
                Dynamic pricing algorithms for options with automated liquidity provision
              </p>
            </CardContent>
          </Card>

          <Card className="bg-slate-800/50 border-slate-700">
            <CardContent className="p-6 text-center">
              <Brain className="h-12 w-12 text-purple-400 mx-auto mb-4" />
              <h3 className="text-xl font-bold text-white mb-2">AI Risk Oracle</h3>
              <p className="text-slate-300">
                Machine learning models integrated on-chain for predictive risk management
              </p>
            </CardContent>
          </Card>
        </div>
      </section>

      {/* CTA Section */}
      <section className="container mx-auto px-4 py-20">
        <Card className="bg-gradient-to-r from-blue-900/50 to-purple-900/50 border-slate-700">
          <CardContent className="p-12 text-center">
            <Globe className="h-16 w-16 text-blue-400 mx-auto mb-6" />
            <h3 className="text-3xl font-bold text-white mb-4">Ready to Trade the Future?</h3>
            <p className="text-slate-300 text-lg mb-8 max-w-2xl mx-auto">
              Join thousands of traders already using NEXUS to access the most advanced derivatives trading platform in
              DeFi.
            </p>
            <Link href="/dashboard">
              <Button
                size="lg"
                className="bg-gradient-to-r from-blue-500 to-purple-600 hover:from-blue-600 hover:to-purple-700"
              >
                Launch Trading Platform <ArrowRight className="ml-2 h-4 w-4" />
              </Button>
            </Link>
          </CardContent>
        </Card>
      </section>

      {/* Footer */}
      <footer className="border-t border-slate-800 bg-slate-900/50">
        <div className="container mx-auto px-4 py-12">
          <div className="grid md:grid-cols-4 gap-8">
            <div>
              <div className="flex items-center space-x-2 mb-4">
                <div className="h-6 w-6 rounded bg-gradient-to-r from-blue-500 to-purple-600"></div>
                <span className="text-xl font-bold text-white">NEXUS</span>
              </div>
              <p className="text-slate-400">The future of derivatives trading on Base blockchain.</p>
            </div>
            <div>
              <h4 className="text-white font-semibold mb-4">Platform</h4>
              <div className="space-y-2">
                <Link href="/dashboard" className="block text-slate-400 hover:text-white transition-colors">
                  Trading
                </Link>
                <Link href="/portfolio" className="block text-slate-400 hover:text-white transition-colors">
                  Portfolio
                </Link>
                <Link href="/analytics" className="block text-slate-400 hover:text-white transition-colors">
                  Analytics
                </Link>
              </div>
            </div>
            <div>
              <h4 className="text-white font-semibold mb-4">Resources</h4>
              <div className="space-y-2">
                <Link href="/docs" className="block text-slate-400 hover:text-white transition-colors">
                  Documentation
                </Link>
                <Link href="/api" className="block text-slate-400 hover:text-white transition-colors">
                  API
                </Link>
                <Link href="/support" className="block text-slate-400 hover:text-white transition-colors">
                  Support
                </Link>
              </div>
            </div>
            <div>
              <h4 className="text-white font-semibold mb-4">Community</h4>
              <div className="space-y-2">
                <a href="#" className="block text-slate-400 hover:text-white transition-colors">
                  Discord
                </a>
                <a href="#" className="block text-slate-400 hover:text-white transition-colors">
                  Twitter
                </a>
                <a href="#" className="block text-slate-400 hover:text-white transition-colors">
                  GitHub
                </a>
              </div>
            </div>
          </div>
          <div className="border-t border-slate-800 mt-8 pt-8 text-center text-slate-400">
            <p>&copy; 2024 NEXUS. All rights reserved. Built on Base blockchain.</p>
          </div>
        </div>
      </footer>
    </div>
  )
}
