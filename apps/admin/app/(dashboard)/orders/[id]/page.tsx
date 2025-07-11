"use client"

import { useState, useEffect } from "react"
import { createClientComponentClient } from "@supabase/auth-helpers-nextjs"
import { ArrowLeft, Loader2, Package, Truck, CheckCircle, AlertCircle } from "lucide-react"
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
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import { Badge } from "@/components/ui/badge"
import { useToast } from "@/components/ui/use-toast"
import { formatCurrency, formatDate } from "@/lib/utils"
import { fetchOrder, fetchUser, updateOrderStatus } from "@/lib/api"
import { logAdminAction } from "@/lib/admin-logs"
import { Order, User } from "@/types"

export default function OrderDetailPage({ params }: { params: { id: string } }) {
  const [order, setOrder] = useState<Order | null>(null)
  const [customer, setCustomer] = useState<User | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const supabase = createClientComponentClient()
  const { toast } = useToast()

  useEffect(() => {
    const getOrderDetails = async () => {
      try {
        setIsLoading(true)
        const orderData = await fetchOrder(params.id)
        
        if (!orderData) {
          notFound()
        }
        
        setOrder(orderData)
        
        // Fetch customer details
        if (orderData.user_id) {
          const userData = await fetchUser(orderData.user_id)
          setCustomer(userData)
        }
      } catch (err) {
        console.error("Error fetching order details:", err)
        setError("Failed to load order details. Please try again.")
      } finally {
        setIsLoading(false)
      }
    }
    
    getOrderDetails()
  }, [params.id])

  // Handle order status update
  const handleStatusUpdate = async (status: Order["status"]) => {
    if (!order) return
    
    try {
      await updateOrderStatus(order.id, status)
      
      // Update local state
      setOrder({ ...order, status })
      
      // Log admin action
      const { data: { user } } = await supabase.auth.getUser()
      if (user) {
        await logAdminAction(
          user.id,
          'update',
          'order',
          order.id,
          { status }
        )
      }
      
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

  // Get status icon
  const getStatusIcon = (status: Order["status"]) => {
    switch (status) {
      case "processing":
        return <AlertCircle className="h-5 w-5 text-yellow-500" />
      case "packed":
        return <Package className="h-5 w-5 text-blue-500" />
      case "out_for_delivery":
        return <Truck className="h-5 w-5 text-purple-500" />
      case "delivered":
        return <CheckCircle className="h-5 w-5 text-green-500" />
      case "cancelled":
        return <AlertCircle className="h-5 w-5 text-red-500" />
      default:
        return null
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

  if (isLoading) {
    return (
      <div className="flex-1 flex items-center justify-center p-4 md:p-8 pt-6">
        <div className="flex flex-col items-center space-y-4">
          <Loader2 className="h-8 w-8 animate-spin text-primary" />
          <p className="text-sm text-muted-foreground">Loading order details...</p>
        </div>
      </div>
    )
  }

  if (error || !order) {
    return (
      <div className="flex-1 flex items-center justify-center p-4 md:p-8 pt-6">
        <div className="flex flex-col items-center space-y-4">
          <p className="text-red-500">{error || "Order not found"}</p>
          <Button asChild>
            <Link href="/orders">Back to Orders</Link>
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
            <Link href="/orders">
              <ArrowLeft className="h-4 w-4" />
              <span className="sr-only">Back</span>
            </Link>
          </Button>
          <h2 className="text-3xl font-bold tracking-tight">
            Order #{order.id.substring(0, 8)}
          </h2>
        </div>
      </div>
      
      <div className="grid gap-4 md:grid-cols-2">
        {/* Order Summary Card */}
        <Card>
          <CardHeader>
            <CardTitle>Order Summary</CardTitle>
            <CardDescription>Order details and status</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <div className="flex justify-between items-center">
                <div>
                  <p className="text-sm font-medium text-muted-foreground">Status</p>
                  <div className="flex items-center gap-2 mt-1">
                    {getStatusIcon(order.status)}
                    <Badge 
                      variant={getStatusBadgeVariant(order.status).variant}
                      className={getStatusBadgeVariant(order.status).className}
                    >
                      {order.status.charAt(0).toUpperCase() + order.status.slice(1)}
                    </Badge>
                  </div>
                </div>
                <div>
                  <p className="text-sm font-medium text-muted-foreground">Date</p>
                  <p className="text-sm mt-1">{formatDate(order.created_at)}</p>
                </div>
              </div>
              
              <div>
                <p className="text-sm font-medium text-muted-foreground">Payment</p>
                <div className="flex items-center gap-2 mt-1">
                  <Badge variant={order.payment_status === "completed" ? "default" : "outline"}>
                    {order.payment_status.charAt(0).toUpperCase() + order.payment_status.slice(1)}
                  </Badge>
                  <span className="text-sm">{order.payment_method}</span>
                </div>
              </div>
              
              <div className="pt-4 border-t">
                <h4 className="font-medium mb-2">Update Order Status</h4>
                <div className="flex flex-wrap gap-2">
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => handleStatusUpdate("processing")}
                    disabled={order.status === "processing"}
                    className={order.status === "processing" ? "bg-yellow-100" : ""}
                  >
                    Processing
                  </Button>
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => handleStatusUpdate("packed")}
                    disabled={order.status === "packed" || order.status === "cancelled"}
                    className={order.status === "packed" ? "bg-blue-100" : ""}
                  >
                    Packed
                  </Button>
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => handleStatusUpdate("out_for_delivery")}
                    disabled={order.status === "out_for_delivery" || order.status === "cancelled"}
                    className={order.status === "out_for_delivery" ? "bg-purple-100" : ""}
                  >
                    Out for Delivery
                  </Button>
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => handleStatusUpdate("delivered")}
                    disabled={order.status === "delivered" || order.status === "cancelled"}
                    className={order.status === "delivered" ? "bg-green-100" : ""}
                  >
                    Delivered
                  </Button>
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => handleStatusUpdate("cancelled")}
                    disabled={order.status === "cancelled" || order.status === "delivered"}
                    className={order.status === "cancelled" ? "bg-red-100" : ""}
                  >
                    Cancelled
                  </Button>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
        
        {/* Customer Info Card */}
        <Card>
          <CardHeader>
            <CardTitle>Customer Information</CardTitle>
            <CardDescription>Details about the customer</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <div>
                <p className="text-sm font-medium text-muted-foreground">Customer ID</p>
                <p className="text-sm mt-1">{order.user_id}</p>
              </div>
              
              {customer && (
                <>
                  <div>
                    <p className="text-sm font-medium text-muted-foreground">Name</p>
                    <p className="text-sm mt-1">
                      {customer.first_name} {customer.last_name}
                    </p>
                  </div>
                  
                  <div>
                    <p className="text-sm font-medium text-muted-foreground">Email</p>
                    <p className="text-sm mt-1">{customer.email}</p>
                  </div>
                  
                  {customer.phone && (
                    <div>
                      <p className="text-sm font-medium text-muted-foreground">Phone</p>
                      <p className="text-sm mt-1">{customer.phone}</p>
                    </div>
                  )}
                </>
              )}
              
              <div className="pt-4 border-t">
                <p className="text-sm font-medium text-muted-foreground">Shipping Address</p>
                <p className="text-sm mt-1">
                  Address ID: {order.address_id}
                  {/* In a real implementation, you would fetch and display the full address */}
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
      
      {/* Order Items */}
      <Card>
        <CardHeader>
          <CardTitle>Order Items</CardTitle>
          <CardDescription>Products in this order</CardDescription>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Product</TableHead>
                <TableHead>Price</TableHead>
                <TableHead>Quantity</TableHead>
                <TableHead className="text-right">Total</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {order.items.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={4} className="h-24 text-center">
                    No items in this order.
                  </TableCell>
                </TableRow>
              ) : (
                order.items.map(item => (
                  <TableRow key={item.id}>
                    <TableCell>
                      <div className="flex items-center gap-3">
                        {item.product && (
                          <>
                            <div className="h-10 w-10 rounded-md overflow-hidden bg-muted">
                              {item.product.image_url && (
                                <Image
                                  src={item.product.image_url}
                                  alt={item.product.name}
                                  width={40}
                                  height={40}
                                  className="h-full w-full object-cover"
                                />
                              )}
                            </div>
                            <div>
                              <div className="font-medium">{item.product.name}</div>
                              <div className="text-xs text-muted-foreground truncate max-w-[200px]">
                                {item.product.description}
                              </div>
                            </div>
                          </>
                        )}
                        {!item.product && (
                          <div>Product ID: {item.product_id}</div>
                        )}
                      </div>
                    </TableCell>
                    <TableCell>{formatCurrency(item.price)}</TableCell>
                    <TableCell>{item.quantity}</TableCell>
                    <TableCell className="text-right">
                      {formatCurrency(item.price * item.quantity)}
                    </TableCell>
                  </TableRow>
                ))
              )}
              <TableRow>
                <TableCell colSpan={3} className="text-right font-medium">
                  Total
                </TableCell>
                <TableCell className="text-right font-bold">
                  {formatCurrency(order.total_amount)}
                </TableCell>
              </TableRow>
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  )
} 