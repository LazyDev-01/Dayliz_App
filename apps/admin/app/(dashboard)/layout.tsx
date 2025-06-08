"use client"

import { useState, useEffect } from "react"
import Link from "next/link"
import { usePathname, useRouter } from "next/navigation"
import { createClientComponentClient } from "@supabase/auth-helpers-nextjs"
import { mockSupabaseClient } from "@/lib/supabase"
import { 
  LayoutDashboard, 
  Package, 
  ShoppingCart, 
  Users, 
  Settings, 
  LogOut,
  Menu,
  Moon,
  Sun,
  Layers
} from "lucide-react"

import { cn } from "@/lib/utils"
import { Button } from "@/components/ui/button"
import {
  Sheet,
  SheetContent,
  SheetTrigger,
} from "@/components/ui/sheet"
import { useTheme } from "next-themes"
import { Separator } from "@/components/ui/separator"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { ModeToggle } from "@/components/mode-toggle"

interface DashboardLayoutProps {
  children: React.ReactNode
}

export default function DashboardLayout({ children }: DashboardLayoutProps) {
  const pathname = usePathname()
  const router = useRouter()
  const [isMounted, setIsMounted] = useState(false)
  const [isAuthenticated, setIsAuthenticated] = useState(false)
  const [adminName, setAdminName] = useState("Demo Admin")
  const [adminEmail, setAdminEmail] = useState("admin@example.com")
  const [supabase, setSupabase] = useState<any>(null)
  
  // Navigation items
  const navItems = [
    {
      title: "Dashboard",
      href: "/dashboard",
      icon: <LayoutDashboard className="mr-2 h-4 w-4" />,
    },
    {
      title: "Products",
      href: "/products",
      icon: <Package className="mr-2 h-4 w-4" />,
    },
    {
      title: "Orders",
      href: "/orders",
      icon: <ShoppingCart className="mr-2 h-4 w-4" />,
    },
    {
      title: "Users",
      href: "/users",
      icon: <Users className="mr-2 h-4 w-4" />,
    },
    {
      title: "Activity Logs",
      href: "/logs",
      icon: <Layers className="mr-2 h-4 w-4" />,
    },
    {
      title: "Settings",
      href: "/settings",
      icon: <Settings className="mr-2 h-4 w-4" />,
    },
  ]

  // Initialize Supabase client and check auth on mount
  useEffect(() => {
    setIsMounted(true)
    
    // Set up the client based on environment
    const isDevelopment = process.env.NODE_ENV !== 'production'
    const hasEnvVars = process.env.NEXT_PUBLIC_SUPABASE_URL && 
                      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
    
    if (isDevelopment || !hasEnvVars) {
      // Use mock client in development
      setSupabase(mockSupabaseClient)
    } else {
      // Use real client in production
      setSupabase(createClientComponentClient())
    }
    
    // Check if user is authenticated from localStorage
    const authStatus = localStorage.getItem('isAuthenticated')
    const userEmail = localStorage.getItem('userEmail')
    
    setIsAuthenticated(authStatus === 'true')
    
    // Update admin details if available
    if (userEmail) {
      setAdminEmail(userEmail)
      // Extract name from email (simple implementation)
      const nameFromEmail = userEmail.split('@')[0]
      setAdminName(nameFromEmail.charAt(0).toUpperCase() + nameFromEmail.slice(1))
    }
    
    // If not authenticated, redirect to login
    if (!authStatus || authStatus !== 'true') {
      router.push('/login')
    }
  }, [router])

  const handleSignOut = async () => {
    // Always clear localStorage
    localStorage.removeItem('isAuthenticated')
    localStorage.removeItem('userEmail')
    
    // Sign out from Supabase if client is available
    if (supabase) {
      await supabase.auth.signOut()
    }
    
    // Redirect to login
    router.push('/login')
  }

  // Don't render anything until client-side code is running
  if (!isMounted) {
    return null
  }

  // Don't render dashboard if not authenticated
  if (!isAuthenticated) {
    return null
  }

  return (
    <div className="flex min-h-screen flex-col">
      {/* Mobile navigation */}
      <header className="sticky top-0 z-40 border-b bg-background lg:hidden">
        <div className="container flex h-16 items-center justify-between">
          <Link href="/dashboard" className="flex items-center space-x-2">
            <span className="font-bold">Dayliz Admin</span>
          </Link>
          <Sheet>
            <SheetTrigger asChild>
              <Button variant="outline" size="icon" className="lg:hidden">
                <Menu className="h-5 w-5" />
                <span className="sr-only">Toggle menu</span>
              </Button>
            </SheetTrigger>
            <SheetContent side="left" className="w-64 sm:w-72">
              <nav className="grid gap-2 py-6">
                {navItems.map((item) => (
                  <Link
                    key={item.href}
                    href={item.href}
                    className={cn(
                      "flex items-center rounded-md px-3 py-2 text-sm font-medium hover:bg-accent hover:text-accent-foreground",
                      pathname === item.href ? "bg-accent" : "transparent"
                    )}
                  >
                    {item.icon}
                    {item.title}
                  </Link>
                ))}
                <Separator className="my-2" />
                <Button
                  variant="ghost"
                  className="flex w-full justify-start text-red-500 hover:bg-red-500/10 hover:text-red-500"
                  onClick={handleSignOut}
                >
                  <LogOut className="mr-2 h-4 w-4" />
                  Sign out
                </Button>
              </nav>
            </SheetContent>
          </Sheet>
        </div>
      </header>

      <div className="flex flex-1">
        {/* Desktop navigation */}
        <aside className="hidden w-64 flex-col border-r bg-background lg:flex">
          <div className="flex h-16 items-center border-b px-6">
            <Link href="/dashboard" className="flex items-center space-x-2">
              <span className="font-bold">Dayliz Admin</span>
            </Link>
          </div>
          <nav className="flex-1 overflow-auto py-6 px-4">
            <div className="grid gap-2">
              {navItems.map((item) => (
                <Link
                  key={item.href}
                  href={item.href}
                  className={cn(
                    "flex items-center rounded-md px-3 py-2 text-sm font-medium hover:bg-accent hover:text-accent-foreground",
                    pathname === item.href ? "bg-accent" : "transparent"
                  )}
                >
                  {item.icon}
                  {item.title}
                </Link>
              ))}
            </div>
          </nav>
          <div className="mt-auto border-t p-4">
            <div className="flex items-center gap-2 py-2">
              <Avatar>
                <AvatarFallback>{adminName.charAt(0)}</AvatarFallback>
              </Avatar>
              <div className="grid gap-0.5 text-sm">
                <div className="font-medium">{adminName}</div>
                <div className="text-muted-foreground">{adminEmail}</div>
              </div>
              <div className="ml-auto">
                <ModeToggle />
              </div>
            </div>
            <Separator className="my-2" />
            <Button
              variant="ghost"
              className="flex w-full justify-start text-red-500 hover:bg-red-500/10 hover:text-red-500"
              onClick={handleSignOut}
            >
              <LogOut className="mr-2 h-4 w-4" />
              Sign out
            </Button>
          </div>
        </aside>

        {/* Main content */}
        <main className="flex-1 overflow-auto">{children}</main>
      </div>
    </div>
  )
} 