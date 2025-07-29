"use client"

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Terminal, GitBranch, Rocket, CheckCircle, AlertCircle, ExternalLink, Copy } from "lucide-react"

export function TestnetDeploymentGuide() {
  const deploymentSteps = [
    {
      title: "Deploy Smart Contracts",
      status: "completed",
      description: "Deploy NEXUS contracts to Sepolia testnet",
      command: "npx hardhat deploy --network sepolia",
      address: "0x1234...5678",
    },
    {
      title: "Initialize Base Pairs",
      status: "completed",
      description: "Add BASE/ETH(Sepolia) trading pair",
      command: "npx hardhat run scripts/init-sepolia-pairs.js",
      address: "0xabcd...efgh",
    },
    {
      title: "Deploy Mock Tokens",
      status: "in-progress",
      description: "Deploy mock BASE token for testing",
      command: "npx hardhat run scripts/deploy-mock-tokens.js",
      address: "Pending...",
    },
    {
      title: "Configure Oracles",
      status: "pending",
      description: "Set up price feeds for testnet",
      command: "npx hardhat run scripts/setup-oracles.js",
      address: "Not started",
    },
  ]

  const contractAddresses = [
    {
      name: "NexusCrossMargin",
      address: "0x742d35Cc6634C0532925a3b8D4C9db96C4b5Da5e",
      verified: true,
    },
    {
      name: "NexusBasePairs",
      address: "0x8ba1f109551bD432803012645Hac136c82C",
      verified: true,
    },
    {
      name: "NexusSepoliaTestnet",
      address: "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0",
      verified: false,
    },
    {
      name: "MockBASEToken",
      address: "0x5FbDB2315678afecb367f032d93F642f64180aa3",
      verified: false,
    },
  ]

  const copyToClipboard = (text: string) => {
    navigator.clipboard.writeText(text)
  }

  return (
    <div className="space-y-6">
      {/* Deployment Status */}
      <Card className="bg-slate-900/50 border-slate-800">
        <CardHeader>
          <CardTitle className="text-white flex items-center">
            <Rocket className="w-5 h-5 mr-2 text-blue-400" />
            Sepolia Testnet Deployment
          </CardTitle>
          <div className="flex items-center space-x-2">
            <Badge variant="outline" className="border-orange-500 text-orange-400">
              Sepolia Network
            </Badge>
            <Badge variant="outline" className="border-green-500 text-green-400">
              2/4 Complete
            </Badge>
          </div>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {deploymentSteps.map((step, index) => (
              <div key={index} className="flex items-start space-x-3 p-3 bg-slate-800/30 rounded-lg">
                <div className="mt-1">
                  {step.status === "completed" && <CheckCircle className="w-5 h-5 text-green-400" />}
                  {step.status === "in-progress" && (
                    <div className="w-5 h-5 border-2 border-blue-400 border-t-transparent rounded-full animate-spin" />
                  )}
                  {step.status === "pending" && <AlertCircle className="w-5 h-5 text-slate-400" />}
                </div>

                <div className="flex-1">
                  <div className="flex items-center justify-between">
                    <h4 className="text-white font-medium">{step.title}</h4>
                    <Badge
                      variant="outline"
                      className={
                        step.status === "completed"
                          ? "border-green-500 text-green-400"
                          : step.status === "in-progress"
                            ? "border-blue-500 text-blue-400"
                            : "border-slate-500 text-slate-400"
                      }
                    >
                      {step.status}
                    </Badge>
                  </div>

                  <p className="text-slate-300 text-sm mt-1">{step.description}</p>

                  <div className="mt-2 p-2 bg-slate-900 rounded border border-slate-700">
                    <div className="flex items-center justify-between">
                      <code className="text-green-400 text-sm">{step.command}</code>
                      <Button
                        size="sm"
                        variant="ghost"
                        onClick={() => copyToClipboard(step.command)}
                        className="h-6 w-6 p-0"
                      >
                        <Copy className="w-3 h-3" />
                      </Button>
                    </div>
                  </div>

                  {step.address && step.address !== "Pending..." && step.address !== "Not started" && (
                    <div className="mt-2 text-xs text-slate-400">
                      Contract: <span className="text-blue-400">{step.address}</span>
                    </div>
                  )}
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Contract Addresses */}
      <Card className="bg-slate-900/50 border-slate-800">
        <CardHeader>
          <CardTitle className="text-white flex items-center">
            <Terminal className="w-5 h-5 mr-2 text-purple-400" />
            Deployed Contracts
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-3">
            {contractAddresses.map((contract, index) => (
              <div key={index} className="flex items-center justify-between p-3 bg-slate-800/30 rounded-lg">
                <div>
                  <div className="text-white font-medium">{contract.name}</div>
                  <div className="text-slate-400 text-sm font-mono">{contract.address}</div>
                </div>

                <div className="flex items-center space-x-2">
                  {contract.verified ? (
                    <Badge variant="outline" className="border-green-500 text-green-400">
                      <CheckCircle className="w-3 h-3 mr-1" />
                      Verified
                    </Badge>
                  ) : (
                    <Badge variant="outline" className="border-yellow-500 text-yellow-400">
                      <AlertCircle className="w-3 h-3 mr-1" />
                      Unverified
                    </Badge>
                  )}

                  <Button
                    size="sm"
                    variant="ghost"
                    onClick={() => copyToClipboard(contract.address)}
                    className="h-8 w-8 p-0"
                  >
                    <Copy className="w-3 h-3" />
                  </Button>

                  <Button size="sm" variant="ghost" className="h-8 w-8 p-0">
                    <ExternalLink className="w-3 h-3" />
                  </Button>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Testing Instructions */}
      <Card className="bg-slate-900/50 border-slate-800">
        <CardHeader>
          <CardTitle className="text-white flex items-center">
            <GitBranch className="w-5 h-5 mr-2 text-green-400" />
            Testing Instructions
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            <div className="p-4 bg-blue-900/20 rounded-lg border border-blue-500/30">
              <h4 className="text-blue-400 font-medium mb-2">1. Get Sepolia ETH</h4>
              <p className="text-slate-300 text-sm mb-2">Get testnet ETH from Sepolia faucets to pay for gas fees.</p>
              <Button
                size="sm"
                variant="outline"
                className="border-blue-500 text-blue-400 hover:bg-blue-500/10 bg-transparent"
              >
                <ExternalLink className="w-3 h-3 mr-1" />
                Sepolia Faucet
              </Button>
            </div>

            <div className="p-4 bg-green-900/20 rounded-lg border border-green-500/30">
              <h4 className="text-green-400 font-medium mb-2">2. Claim Test Tokens</h4>
              <p className="text-slate-300 text-sm">
                Use the testnet faucet to claim 10,000 BASE tokens and 5 ETH for testing trades.
              </p>
            </div>

            <div className="p-4 bg-purple-900/20 rounded-lg border border-purple-500/30">
              <h4 className="text-purple-400 font-medium mb-2">3. Test Trading Features</h4>
              <ul className="text-slate-300 text-sm space-y-1">
                <li>• Execute market and limit orders</li>
                <li>• Test cross-margin functionality</li>
                <li>• Simulate price movements</li>
                <li>• Verify liquidation mechanisms</li>
              </ul>
            </div>

            <div className="p-4 bg-orange-900/20 rounded-lg border border-orange-500/30">
              <h4 className="text-orange-400 font-medium mb-2">4. Report Issues</h4>
              <p className="text-slate-300 text-sm">
                Found bugs or issues? Report them on our GitHub repository for quick fixes.
              </p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
