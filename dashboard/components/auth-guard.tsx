'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { canAccessDashboard, getBackendClient } from '@/lib/backend-client'

interface AuthGuardProps {
  children: React.ReactNode
}

export default function AuthGuard({ children }: AuthGuardProps) {
  const [isChecking, setIsChecking] = useState(true)
  const router = useRouter()

  useEffect(() => {
    let active = true

    const checkAuth = async () => {
      const hasSession = await getBackendClient().ensureSession()
      if (!active) return

      if (!hasSession || !canAccessDashboard()) {
        router.replace('/login')
        return
      }
      setIsChecking(false)
    }

    void checkAuth()
    return () => {
      active = false
    }
  }, [router])

  if (isChecking) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary mx-auto"></div>
          <p className="mt-2 text-muted-foreground">Verifying authentication...</p>
        </div>
      </div>
    )
  }

  return <>{children}</>
}
