"use client"

import { useRouter } from "next/navigation"
import { Button } from "@/components/ui/button"
import { createClientComponentClient } from "@supabase/auth-helpers-nextjs"

export default function UnauthorizedPage() {
  const router = useRouter()
  const supabase = createClientComponentClient()

  const handleLogout = async () => {
    await supabase.auth.signOut()
    router.push('/login')
  }

  return (
    <div className="flex h-screen w-full flex-col items-center justify-center bg-muted/40">
      <div className="max-w-md text-center space-y-6">
        <div className="space-y-2">
          <h1 className="text-4xl font-bold tracking-tight">Unauthorized Access</h1>
          <p className="text-muted-foreground">
            You don't have permission to access the admin dashboard. This area is restricted to administrators only.
          </p>
        </div>
        <div className="flex justify-center gap-4">
          <Button onClick={handleLogout} variant="default">
            Return to Login
          </Button>
        </div>
      </div>
    </div>
  )
} 