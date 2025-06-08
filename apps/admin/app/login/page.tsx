"use client"

import { useState, useEffect } from "react"
import { useRouter } from "next/navigation"
import { createClientComponentClient } from "@supabase/auth-helpers-nextjs"
import { mockSupabaseClient } from "@/lib/supabase"
import Image from "next/image"
import { z } from "zod"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"

import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import {
  Form,
  FormControl,
  FormDescription,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form"
import { toast } from "@/components/ui/use-toast"

const loginFormSchema = z.object({
  email: z.string().email({ message: "Please enter a valid email address" }),
  password: z.string().min(6, { message: "Password must be at least 6 characters" }),
})

type LoginFormValues = z.infer<typeof loginFormSchema>

export default function LoginPage() {
  const router = useRouter()
  const [isLoading, setIsLoading] = useState(false)
  const [isMounted, setIsMounted] = useState(false)
  
  // Initialize with empty client - we'll set the real one after mount
  const [supabase, setSupabase] = useState<any>(null)
  
  // Set up the client after mount to avoid hydration issues
  useEffect(() => {
    setIsMounted(true)
    
    // Use real client in production, mock in development
    const isDevelopment = process.env.NODE_ENV !== 'production'
    const hasEnvVars = process.env.NEXT_PUBLIC_SUPABASE_URL && 
                      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
    
    if (isDevelopment || !hasEnvVars) {
      // Use mock client in development
      setSupabase(mockSupabaseClient)
      console.log("Using mock Supabase client")
    } else {
      // Use real client in production
      setSupabase(createClientComponentClient())
      console.log("Using real Supabase client")
    }
  }, [])

  const form = useForm<LoginFormValues>({
    resolver: zodResolver(loginFormSchema),
    defaultValues: {
      email: "",
      password: "",
    },
  })

  async function onSubmit(data: LoginFormValues) {
    if (!supabase) {
      toast({
        title: "Error",
        description: "Authentication service not initialized",
        variant: "destructive",
      })
      return
    }
    
    setIsLoading(true)
    
    try {
      // Always use signInWithPassword method whether it's real or mock
      const { error } = await supabase.auth.signInWithPassword({
        email: data.email,
        password: data.password,
      })

      if (error) {
        throw new Error(error.message)
      }

      // Store login state in localStorage to persist across sessions
      localStorage.setItem('isAuthenticated', 'true')
      localStorage.setItem('userEmail', data.email)
      
      toast({
        title: "Login successful",
        description: "Redirecting to dashboard...",
      })
      
      // Redirect to dashboard
      router.push('/dashboard')
      router.refresh()
    } catch (error) {
      toast({
        title: "Login failed",
        description: error instanceof Error ? error.message : "Something went wrong",
        variant: "destructive",
      })
    } finally {
      setIsLoading(false)
    }
  }

  // Don't render until client-side code is running
  if (!isMounted || !supabase) {
    return (
      <div className="flex h-screen items-center justify-center">
        <div className="text-center">Loading...</div>
      </div>
    )
  }

  return (
    <div className="flex h-screen w-full items-center justify-center bg-muted/40">
      <Card className="w-full max-w-md">
        <CardHeader className="space-y-2 text-center">
          <div className="flex justify-center mb-4">
            <Image
              src="/logo.png"
              alt="Dayliz Logo"
              width={80}
              height={80}
              priority
            />
          </div>
          <CardTitle className="text-2xl font-bold">Dayliz Admin Panel</CardTitle>
          <CardDescription>
            Enter your credentials to access the admin dashboard
            {process.env.NODE_ENV !== 'production' && (
              <div className="mt-2 px-3 py-1 rounded bg-yellow-50 text-yellow-700 text-xs">
                Development Mode: Any email/password combination will work
              </div>
            )}
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Form {...form}>
            <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
              <FormField
                control={form.control}
                name="email"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Email</FormLabel>
                    <FormControl>
                      <Input
                        placeholder="admin@dayliz.com"
                        {...field}
                        disabled={isLoading}
                      />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={form.control}
                name="password"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Password</FormLabel>
                    <FormControl>
                      <Input
                        type="password"
                        placeholder="••••••••"
                        {...field}
                        disabled={isLoading}
                      />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <Button type="submit" className="w-full" disabled={isLoading}>
                {isLoading ? "Signing in..." : "Sign in"}
              </Button>
            </form>
          </Form>
        </CardContent>
        <CardFooter className="text-center text-sm text-muted-foreground">
          <p className="w-full">
            This portal is exclusively for authorized administrators.
          </p>
        </CardFooter>
      </Card>
    </div>
  )
} 