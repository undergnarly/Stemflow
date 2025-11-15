'use client'

import { ThemeToggle } from '@/components/theme-toggle'

export default function HomePage() {
  return (
    <div className="flex min-h-screen flex-col">
      {/* Header with theme toggle */}
      <header className="border-b border-border">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center justify-end">
            <ThemeToggle />
          </div>
        </div>
      </header>

      {/* Main content */}
      <div className="flex flex-1 items-center justify-center p-8">
        <div className="text-center max-w-2xl">
          <h1 className="text-4xl md:text-5xl font-bold tracking-tight">
            Production Tracker
          </h1>
          <p className="mt-4 text-lg text-muted-foreground">
            AI-powered production assistant for Ableton Live
          </p>
          <div className="mt-8 flex gap-4 justify-center flex-wrap">
            <a
              href="/login"
              className="rounded-md bg-primary px-6 py-3 text-sm font-medium text-primary-foreground hover:bg-primary/90 transition-colors"
            >
              Login
            </a>
            <a
              href="/register"
              className="rounded-md border border-input bg-background px-6 py-3 text-sm font-medium hover:bg-accent hover:text-accent-foreground transition-colors"
            >
              Register
            </a>
          </div>
        </div>
      </div>
    </div>
  )
}
