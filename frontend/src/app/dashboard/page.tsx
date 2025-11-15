'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'

export default function DashboardPage() {
  const router = useRouter()
  const [user, setUser] = useState<any>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    // Check if user is authenticated
    const token = localStorage.getItem('access_token')
    if (!token) {
      router.push('/login')
      return
    }

    // Fetch user data
    fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/auth/me`, {
      headers: {
        'Authorization': `Bearer ${token}`,
      },
    })
      .then(res => {
        if (!res.ok) {
          throw new Error('Unauthorized')
        }
        return res.json()
      })
      .then(data => {
        setUser(data)
        setLoading(false)
      })
      .catch(() => {
        localStorage.removeItem('access_token')
        localStorage.removeItem('refresh_token')
        router.push('/login')
      })
  }, [router])

  const handleLogout = () => {
    localStorage.removeItem('access_token')
    localStorage.removeItem('refresh_token')
    router.push('/')
  }

  const handleDownloadDevice = () => {
    // Trigger download of Ableton device package
    const link = document.createElement('a')
    link.href = '/downloads/ProductionTracker-v1.0.1.tar.gz'
    link.download = 'ProductionTracker-v1.0.1.tar.gz'
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
  }

  if (loading) {
    return (
      <div className="flex min-h-screen items-center justify-center">
        <div className="text-center">
          <p className="text-lg">Loading...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-background">
      {/* Header */}
      <header className="border-b border-border">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-4">
              <h1 className="text-2xl font-bold">Production Tracker</h1>
            </div>
            <div className="flex items-center space-x-4">
              <span className="text-sm text-muted-foreground">
                {user?.email}
              </span>
              <button
                onClick={handleLogout}
                className="rounded-md border border-input bg-background px-3 py-1.5 text-sm hover:bg-accent hover:text-accent-foreground"
              >
                Logout
              </button>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="container mx-auto px-4 py-8">
        <div className="max-w-4xl mx-auto space-y-8">
          {/* Welcome Section */}
          <div className="rounded-lg border border-border bg-card p-6">
            <h2 className="text-2xl font-bold mb-2">
              Welcome back, {user?.name}!
            </h2>
            <p className="text-muted-foreground">
              AI-powered production assistant for Ableton Live
            </p>
          </div>

          {/* Download Device Section */}
          <div className="rounded-lg border border-border bg-card p-6">
            <div className="flex items-start justify-between">
              <div className="flex-1">
                <h3 className="text-xl font-semibold mb-2">
                  Ableton Live Device
                </h3>
                <p className="text-muted-foreground mb-4">
                  Download and install the Production Tracker device for Ableton Live.
                  This device connects your DAW with the tracking system to monitor
                  your production sessions automatically.
                </p>
                <div className="space-y-2 text-sm text-muted-foreground">
                  <p>• Automatic session tracking</p>
                  <p>• Real-time progress monitoring</p>
                  <p>• AI-powered suggestions</p>
                  <p>• Version control integration</p>
                </div>
              </div>
              <div className="ml-6">
                <button
                  onClick={handleDownloadDevice}
                  className="rounded-md bg-primary px-6 py-3 text-sm font-medium text-primary-foreground hover:bg-primary/90 focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2"
                >
                  Download Device
                </button>
              </div>
            </div>
          </div>

          {/* Quick Stats */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="rounded-lg border border-border bg-card p-4">
              <div className="text-sm text-muted-foreground mb-1">Projects</div>
              <div className="text-2xl font-bold">0</div>
            </div>
            <div className="rounded-lg border border-border bg-card p-4">
              <div className="text-sm text-muted-foreground mb-1">Total Time</div>
              <div className="text-2xl font-bold">0h</div>
            </div>
            <div className="rounded-lg border border-border bg-card p-4">
              <div className="text-sm text-muted-foreground mb-1">Sessions</div>
              <div className="text-2xl font-bold">0</div>
            </div>
          </div>

          {/* Getting Started */}
          <div className="rounded-lg border border-border bg-card p-6">
            <h3 className="text-xl font-semibold mb-4">Getting Started</h3>
            <div className="space-y-3">
              <div className="flex items-start space-x-3">
                <div className="flex h-6 w-6 items-center justify-center rounded-full bg-primary text-xs text-primary-foreground">
                  1
                </div>
                <div className="flex-1">
                  <p className="font-medium">Download the Ableton device</p>
                  <p className="text-sm text-muted-foreground">
                    Click the button above to download the device
                  </p>
                </div>
              </div>
              <div className="flex items-start space-x-3">
                <div className="flex h-6 w-6 items-center justify-center rounded-full bg-muted text-xs">
                  2
                </div>
                <div className="flex-1">
                  <p className="font-medium">Install in Ableton Live</p>
                  <p className="text-sm text-muted-foreground">
                    Drag and drop the device into your Ableton project
                  </p>
                </div>
              </div>
              <div className="flex items-start space-x-3">
                <div className="flex h-6 w-6 items-center justify-center rounded-full bg-muted text-xs">
                  3
                </div>
                <div className="flex-1">
                  <p className="font-medium">Start tracking</p>
                  <p className="text-sm text-muted-foreground">
                    The device will automatically track your sessions
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
  )
}
