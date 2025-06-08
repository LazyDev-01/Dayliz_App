"use client"

import { useState, useEffect } from "react"
import { ArrowLeft, Loader2, User as UserIcon, Mail, Phone, Calendar, Shield } from "lucide-react"
import Link from "next/link"
import { notFound } from "next/navigation"
import Image from "next/image"

import { Button } from "@/components/ui/button"
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { useToast } from "@/components/ui/use-toast"
import { formatDate } from "@/lib/utils"
import { fetchUser } from "@/lib/api"
import { User } from "@/types"

export default function UserProfilePage({ params }: { params: { id: string } }) {
  const [user, setUser] = useState<User | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const { toast } = useToast()

  useEffect(() => {
    const getUserDetails = async () => {
      try {
        setIsLoading(true)
        const userData = await fetchUser(params.id)
        
        if (!userData) {
          notFound()
        }
        
        setUser(userData)
      } catch (err) {
        console.error("Error fetching user details:", err)
        setError("Failed to load user details. Please try again.")
      } finally {
        setIsLoading(false)
      }
    }
    
    getUserDetails()
  }, [params.id])

  // Get user display name
  const getUserDisplayName = (user: User): string => {
    if (user.first_name || user.last_name) {
      return `${user.first_name || ''} ${user.last_name || ''}`.trim()
    }
    return user.email.split('@')[0]
  }

  if (isLoading) {
    return (
      <div className="flex-1 flex items-center justify-center p-4 md:p-8 pt-6">
        <div className="flex flex-col items-center space-y-4">
          <Loader2 className="h-8 w-8 animate-spin text-primary" />
          <p className="text-sm text-muted-foreground">Loading user details...</p>
        </div>
      </div>
    )
  }

  if (error || !user) {
    return (
      <div className="flex-1 flex items-center justify-center p-4 md:p-8 pt-6">
        <div className="flex flex-col items-center space-y-4">
          <p className="text-red-500">{error || "User not found"}</p>
          <Button asChild>
            <Link href="/users">Back to Users</Link>
          </Button>
        </div>
      </div>
    )
  }

  return (
    <div className="flex-1 space-y-4 p-4 md:p-8 pt-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-2">
          <Button variant="outline" size="icon" asChild>
            <Link href="/users">
              <ArrowLeft className="h-4 w-4" />
              <span className="sr-only">Back</span>
            </Link>
          </Button>
          <h2 className="text-3xl font-bold tracking-tight">
            User Profile
          </h2>
        </div>
      </div>
      
      <div className="grid gap-6">
        {/* User Profile Card */}
        <Card>
          <CardHeader>
            <CardTitle>User Information</CardTitle>
            <CardDescription>
              Basic information about the user account
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="flex flex-col md:flex-row gap-6">
              {/* User Avatar */}
              <div className="flex flex-col items-center">
                <div className="h-32 w-32 rounded-full overflow-hidden bg-muted flex items-center justify-center mb-2">
                  {user.profile_image_url ? (
                    <Image
                      src={user.profile_image_url}
                      alt={getUserDisplayName(user)}
                      width={128}
                      height={128}
                      className="h-full w-full object-cover"
                    />
                  ) : (
                    <UserIcon className="h-16 w-16 text-muted-foreground" />
                  )}
                </div>
                {user.is_admin && (
                  <Badge className="bg-purple-100 text-purple-800 hover:bg-purple-100">
                    <Shield className="h-3 w-3 mr-1" /> Admin
                  </Badge>
                )}
              </div>
              
              {/* User Details */}
              <div className="flex-1 space-y-4">
                <div>
                  <h3 className="text-xl font-semibold">{getUserDisplayName(user)}</h3>
                  <div className="flex flex-col gap-2 mt-2">
                    <div className="flex items-center gap-2 text-muted-foreground">
                      <Mail className="h-4 w-4" />
                      <span>{user.email}</span>
                    </div>
                    
                    {user.phone && (
                      <div className="flex items-center gap-2 text-muted-foreground">
                        <Phone className="h-4 w-4" />
                        <span>{user.phone}</span>
                      </div>
                    )}
                    
                    <div className="flex items-center gap-2 text-muted-foreground">
                      <Calendar className="h-4 w-4" />
                      <span>Joined on {formatDate(user.created_at)}</span>
                    </div>
                  </div>
                </div>
                
                <div className="pt-4 border-t">
                  <h4 className="text-sm font-medium text-muted-foreground mb-2">Account ID</h4>
                  <p className="text-sm font-mono bg-muted p-2 rounded">{user.id}</p>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
        
        {/* Additional sections can be added here as needed */}
        {/* For example: Order History, Addresses, etc. */}
      </div>
    </div>
  )
}
