"use client"

import { useState, useEffect } from "react"
import { createClientComponentClient } from "@supabase/auth-helpers-nextjs"
import { useRouter } from "next/navigation"
import { Search, Filter, Eye, ArrowUpDown } from "lucide-react"

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
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { formatCurrency, formatDate } from "@/lib/utils"
import { useToast } from "@/components/ui/use-toast"
import { logAdminAction } from "@/lib/admin-logs"
import { fetchOrders, updateOrderStatus } from "@/lib/api"
import { Order } from "@/types"

// Demo orders data for testing
const demoOrders: Order[] = [
  {
    id: "ORD-001",
    user_id: "USR-123",
    status: "processing",
    total_amount: 78.95,
    created_at: "2023-06-05T14:30:00Z",
    updated_at: "2023-06-05T14:30:00Z",
    payment_status: "pending",
    payment_method: "credit_card",
    address_id: "ADDR-001",
    items: []
  },
  {
    id: "ORD-002",
    user_id: "USR-456",
    status: "packed",
    total_amount: 124.50,
    created_at: "2023-06-04T09:15:00Z",
    updated_at: "2023-06-04T15:20:00Z",
    payment_status: "completed",
    payment_method: "credit_card",
    address_id: "ADDR-002",
    items: []
  },
  {
    id: "ORD-003",
    user_id: "USR-789",
    status: "out_for_delivery",
    total_amount: 59.99,
    created_at: "2023-06-03T11:45:00Z",
    updated_at: "2023-06-04T08:30:00Z",
    payment_status: "completed",
    payment_method: "paypal",
    address_id: "ADDR-003",
    items: []
  },
  {
    id: "ORD-004",
    user_id: "USR-234",
    status: "delivered",
    total_amount: 210.75,
    created_at: "2023-06-01T16:20:00Z",
    updated_at: "2023-06-03T10:15:00Z",
    payment_status: "completed",
    payment_method: "credit_card",
    address_id: "ADDR-004",
    items: []
  },
  {
    id: "ORD-005",
    user_id: "USR-567",
    status: "cancelled",
    total_amount: 45.25,
    created_at: "2023-05-31T08:50:00Z",
    updated_at: "2023-05-31T09:30:00Z",
    payment_status: "failed",
    payment_method: "credit_card",
    address_id: "ADDR-005",
    items: []
  }
];

export default function OrdersPage() {
  const [orders, setOrders] = useState<Order[]>([])
  const [searchQuery, setSearchQuery] = useState("")
  const [statusFilter, setStatusFilter] = useState("all")
  const [sortField, setSortField] = useState<"created_at" | "total_amount">("created_at")
  const [sortDirection, setSortDirection] = useState<"asc" | "desc">("desc")
  const [isLoading, setIsLoading] = useState(true)
  const router = useRouter()
  // Comment out Supabase client for testing
  // const supabase = createClientComponentClient()
  const { toast } = useToast()

  // Fetch orders
  useEffect(() => {
    const fetchData = async () => {
      try {
        setIsLoading(true)
        // For testing, use demo data instead of Supabase
        // const ordersData = await fetchOrders()
        
        // Simulate API delay
        await new Promise(resolve => setTimeout(resolve, 500))
        
        setOrders(demoOrders)
      } catch (error) {
        console.error('Error fetching orders:', error)
        toast({
          title: "Error fetching data",
          description: "Failed to load orders",
          variant: "destructive"
        })
      } finally {
        setIsLoading(false)
      }
    }
    
    fetchData()
  }, [toast])

  // Filter and sort orders
  const filteredOrders = orders
    .filter(order => {
      // Filter by search query (order ID or user ID)
      const matchesSearch = order.id.toLowerCase().includes(searchQuery.toLowerCase()) ||
                           order.user_id.toLowerCase().includes(searchQuery.toLowerCase())
      
      // Filter by status
      const matchesStatus = statusFilter === "all" || order.status === statusFilter
      
      return matchesSearch && matchesStatus
    })
    .sort((a, b) => {
      // Sort by selected field
      if (sortField === "created_at") {
        return sortDirection === "asc" 
          ? new Date(a.created_at).getTime() - new Date(b.created_at).getTime()
          : new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
      } else {
        return sortDirection === "asc" 
          ? a.total_amount - b.total_amount
          : b.total_amount - a.total_amount
      }
    })

  // Handle order status update
  const handleStatusUpdate = async (orderId: string, status: Order["status"]) => {
    try {
      // For testing, just update local state
      // await updateOrderStatus(orderId, status)
      
      // Update local state
      setOrders(orders.map(order => 
        order.id === orderId ? { ...order, status } : order
      ))
      
      // Log admin action - disabled for testing
      // const { data: { user } } = await supabase.auth.getUser()
      // if (user) {
      //   await logAdminAction(
      //     user.id,
      //     'update',
      //     'order',
      //     orderId,
      //     { status }
      //   )
      // }
      
      toast({
        title: "Order updated",
        description: `Order status changed to ${status}`,
      })
    } catch (error) {
      console.error('Error updating order:', error)
      toast({
        title: "Error",
        description: "Failed to update order status",
        variant: "destructive"
      })
    }
  }

  // Toggle sort direction
  const toggleSort = (field: "created_at" | "total_amount") => {
    if (sortField === field) {
      setSortDirection(sortDirection === "asc" ? "desc" : "asc")
    } else {
      setSortField(field)
      setSortDirection("desc")
    }
  }

  // Get badge variant based on order status
  const getStatusBadgeVariant = (status: Order["status"]) => {
    switch (status) {
      case "processing":
        return { variant: "outline" as const, className: "bg-yellow-100 text-yellow-800 hover:bg-yellow-100" }
      case "packed":
        return { variant: "outline" as const, className: "bg-blue-100 text-blue-800 hover:bg-blue-100" }
      case "out_for_delivery":
        return { variant: "outline" as const, className: "bg-purple-100 text-purple-800 hover:bg-purple-100" }
      case "delivered":
        return { variant: "outline" as const, className: "bg-green-100 text-green-800 hover:bg-green-100" }
      case "cancelled":
        return { variant: "outline" as const, className: "bg-red-100 text-red-800 hover:bg-red-100" }
      default:
        return { variant: "outline" as const, className: "" }
    }
  }

  return (
    <div className="flex-1 space-y-4 p-4 md:p-8 pt-6">
      <div className="flex items-center justify-between">
        <h2 className="text-3xl font-bold tracking-tight">Orders</h2>
      </div>
      
      <Card>
        <CardHeader>
          <CardTitle>Order Management</CardTitle>
          <CardDescription>
            View and manage customer orders. Update order status and track deliveries.
          </CardDescription>
        </CardHeader>
        <CardContent>
          {/* Filters */}
          <div className="flex flex-col md:flex-row gap-4 mb-6">
            <div className="relative flex-1">
              <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="Search by order ID or customer ID..."
                className="pl-8"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
              />
            </div>
            <div className="flex items-center gap-2">
              <Filter className="h-4 w-4 text-muted-foreground" />
              <Select value={statusFilter} onValueChange={setStatusFilter}>
                <SelectTrigger className="w-[180px]">
                  <SelectValue placeholder="Status" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Statuses</SelectItem>
                  <SelectItem value="processing">Processing</SelectItem>
                  <SelectItem value="packed">Packed</SelectItem>
                  <SelectItem value="out_for_delivery">Out for Delivery</SelectItem>
                  <SelectItem value="delivered">Delivered</SelectItem>
                  <SelectItem value="cancelled">Cancelled</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
          
          {/* Orders Table */}
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Order ID</TableHead>
                  <TableHead>Customer</TableHead>
                  <TableHead 
                    className="cursor-pointer hover:text-primary"
                    onClick={() => toggleSort("created_at")}
                  >
                    <div className="flex items-center gap-1">
                      Date
                      <ArrowUpDown className="h-4 w-4" />
                    </div>
                  </TableHead>
                  <TableHead 
                    className="cursor-pointer hover:text-primary"
                    onClick={() => toggleSort("total_amount")}
                  >
                    <div className="flex items-center gap-1">
                      Amount
                      <ArrowUpDown className="h-4 w-4" />
                    </div>
                  </TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Payment</TableHead>
                  <TableHead className="text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {isLoading ? (
                  <TableRow>
                    <TableCell colSpan={7} className="h-24 text-center">
                      Loading orders...
                    </TableCell>
                  </TableRow>
                ) : filteredOrders.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={7} className="h-24 text-center">
                      No orders found.
                    </TableCell>
                  </TableRow>
                ) : (
                  filteredOrders.map(order => (
                    <TableRow key={order.id}>
                      <TableCell className="font-medium">
                        #{order.id.substring(0, 8)}
                      </TableCell>
                      <TableCell>
                        {order.user_id.substring(0, 8)}...
                      </TableCell>
                      <TableCell>{formatDate(order.created_at)}</TableCell>
                      <TableCell>{formatCurrency(order.total_amount)}</TableCell>
                      <TableCell>
                        <Badge 
                          variant={getStatusBadgeVariant(order.status).variant}
                          className={getStatusBadgeVariant(order.status).className}
                        >
                          {order.status.charAt(0).toUpperCase() + order.status.slice(1)}
                        </Badge>
                      </TableCell>
                      <TableCell>
                        <Badge variant={order.payment_status === "completed" ? "default" : "outline"}>
                          {order.payment_status.charAt(0).toUpperCase() + order.payment_status.slice(1)}
                        </Badge>
                      </TableCell>
                      <TableCell className="text-right">
                        <div className="flex justify-end gap-2">
                          <Button
                            variant="ghost"
                            size="icon"
                            onClick={() => router.push(`/orders/${order.id}`)}
                          >
                            <Eye className="h-4 w-4" />
                            <span className="sr-only">View</span>
                          </Button>
                          
                          {/* Status update dropdown */}
                          <Select
                            value={order.status}
                            onValueChange={(value) => 
                              handleStatusUpdate(order.id, value as Order["status"])
                            }
                            disabled={order.status === "delivered" || order.status === "cancelled"}
                          >
                            <SelectTrigger className="w-[110px] h-8">
                              <SelectValue placeholder="Update" />
                            </SelectTrigger>
                            <SelectContent>
                              <SelectItem value="processing">Processing</SelectItem>
                              <SelectItem value="packed">Packed</SelectItem>
                              <SelectItem value="out_for_delivery">Out for Delivery</SelectItem>
                              <SelectItem value="delivered">Delivered</SelectItem>
                              <SelectItem value="cancelled">Cancelled</SelectItem>
                            </SelectContent>
                          </Select>
                        </div>
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