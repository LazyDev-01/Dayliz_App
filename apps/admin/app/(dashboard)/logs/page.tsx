"use client"

import { useState, useEffect } from "react"
import { Search, ArrowUpDown } from "lucide-react"
import Image from "next/image"

import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { formatDateTime } from "@/lib/utils"
import { useToast } from "@/components/ui/use-toast"
import { fetchAdminLogs } from "@/lib/api"
import { AdminLog } from "@/types"

export default function LogsPage() {
  const [logs, setLogs] = useState<AdminLog[]>([])
  const [searchQuery, setSearchQuery] = useState("")
  const [sortDirection, setSortDirection] = useState<"asc" | "desc">("desc")
  const [isLoading, setIsLoading] = useState(true)
  const { toast } = useToast()

  // Fetch logs
  useEffect(() => {
    const fetchData = async () => {
      try {
        setIsLoading(true)
        const logsData = await fetchAdminLogs()
        setLogs(logsData)
      } catch (error) {
        console.error('Error fetching logs:', error)
        toast({
          title: "Error fetching data",
          description: "Failed to load admin logs",
          variant: "destructive"
        })
      } finally {
        setIsLoading(false)
      }
    }
    
    fetchData()
  }, [toast])

  // Filter and sort logs
  const filteredLogs = logs
    .filter(log => {
      // Filter by search query (action, resource type, admin name)
      return (
        log.action.toLowerCase().includes(searchQuery.toLowerCase()) ||
        log.resource_type.toLowerCase().includes(searchQuery.toLowerCase()) ||
        (log.admin?.first_name && log.admin.first_name.toLowerCase().includes(searchQuery.toLowerCase())) ||
        (log.admin?.last_name && log.admin.last_name.toLowerCase().includes(searchQuery.toLowerCase())) ||
        (log.admin?.email && log.admin.email.toLowerCase().includes(searchQuery.toLowerCase()))
      )
    })
    .sort((a, b) => {
      // Sort by created_at
      return sortDirection === "asc" 
        ? new Date(a.created_at).getTime() - new Date(b.created_at).getTime()
        : new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
    })

  // Toggle sort direction
  const toggleSort = () => {
    setSortDirection(sortDirection === "asc" ? "desc" : "asc")
  }

  // Get admin display name
  const getAdminDisplayName = (log: AdminLog): string => {
    if (!log.admin) return 'Unknown';
    
    if (log.admin.first_name || log.admin.last_name) {
      return `${log.admin.first_name || ''} ${log.admin.last_name || ''}`.trim()
    }
    return log.admin.email.split('@')[0]
  }

  // Get action badge variant
  const getActionBadgeVariant = (action: string) => {
    switch (action) {
      case 'create':
        return { variant: "default" as const, className: "bg-green-100 text-green-800 hover:bg-green-100" }
      case 'update':
        return { variant: "outline" as const, className: "bg-blue-100 text-blue-800 hover:bg-blue-100" }
      case 'delete':
        return { variant: "outline" as const, className: "bg-red-100 text-red-800 hover:bg-red-100" }
      default:
        return { variant: "outline" as const, className: "" }
    }
  }

  return (
    <div className="flex-1 space-y-4 p-4 md:p-8 pt-6">
      <div className="flex items-center justify-between">
        <h2 className="text-3xl font-bold tracking-tight">Activity Logs</h2>
      </div>
      
      <Card>
        <CardHeader>
          <CardTitle>Admin Activity</CardTitle>
          <CardDescription>
            Track all admin actions performed in the system
          </CardDescription>
        </CardHeader>
        <CardContent>
          {/* Search */}
          <div className="flex flex-col md:flex-row gap-4 mb-6">
            <div className="relative flex-1">
              <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="Search by action, resource, or admin..."
                className="pl-8"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
              />
            </div>
          </div>
          
          {/* Logs Table */}
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Admin</TableHead>
                  <TableHead>Action</TableHead>
                  <TableHead>Resource</TableHead>
                  <TableHead 
                    className="cursor-pointer hover:text-primary"
                    onClick={toggleSort}
                  >
                    <div className="flex items-center gap-1">
                      Timestamp
                      <ArrowUpDown className="h-4 w-4" />
                    </div>
                  </TableHead>
                  <TableHead>Details</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {isLoading ? (
                  <TableRow>
                    <TableCell colSpan={5} className="h-24 text-center">
                      Loading logs...
                    </TableCell>
                  </TableRow>
                ) : filteredLogs.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={5} className="h-24 text-center">
                      No logs found.
                    </TableCell>
                  </TableRow>
                ) : (
                  filteredLogs.map(log => (
                    <TableRow key={log.id}>
                      <TableCell>
                        <div className="font-medium">{getAdminDisplayName(log)}</div>
                        <div className="text-xs text-muted-foreground">{log.admin_id.substring(0, 8)}...</div>
                      </TableCell>
                      <TableCell>
                        <Badge 
                          variant={getActionBadgeVariant(log.action).variant}
                          className={getActionBadgeVariant(log.action).className}
                        >
                          {log.action.charAt(0).toUpperCase() + log.action.slice(1)}
                        </Badge>
                      </TableCell>
                      <TableCell>
                        <div className="font-medium capitalize">{log.resource_type}</div>
                        <div className="text-xs text-muted-foreground">{log.resource_id.substring(0, 8)}...</div>
                      </TableCell>
                      <TableCell>{formatDateTime(log.created_at)}</TableCell>
                      <TableCell>
                        {log.details ? (
                          <pre className="text-xs bg-muted p-2 rounded overflow-x-auto max-w-[200px]">
                            {JSON.stringify(log.details, null, 2)}
                          </pre>
                        ) : (
                          <span className="text-muted-foreground">No details</span>
                        )}
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </div>
        </CardContent>
      </Card>
    </div>
  )
} 