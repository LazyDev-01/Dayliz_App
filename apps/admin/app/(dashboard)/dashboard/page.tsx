"use client"

import { useState, useEffect } from "react"
import { createClientComponentClient } from "@supabase/auth-helpers-nextjs"
import { 
  Card, 
  CardContent, 
  CardDescription, 
  CardHeader, 
  CardTitle 
} from "@/components/ui/card"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import {
  ArrowUpRight,
  ArrowDownRight,
  Users,
  ShoppingCart,
  Package,
  CreditCard
} from "lucide-react"
import { 
  ResponsiveContainer,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  LineChart,
  Line
} from "recharts"
import { formatCurrency, calculatePercentChange } from "@/lib/utils"

// Demo data - replace with actual data from Supabase
const demoData = {
  dailyOrders: [
    { name: "Mon", orders: 13 },
    { name: "Tue", orders: 17 },
    { name: "Wed", orders: 15 },
    { name: "Thu", orders: 21 },
    { name: "Fri", orders: 25 },
    { name: "Sat", orders: 32 },
    { name: "Sun", orders: 27 },
  ],
  monthlySales: [
    { name: "Jan", sales: 12000 },
    { name: "Feb", sales: 15000 },
    { name: "Mar", sales: 18000 },
    { name: "Apr", sales: 21000 },
    { name: "May", sales: 25000 },
    { name: "Jun", sales: 29000 },
  ],
  stats: {
    revenue: {
      current: 275000,
      previous: 245000,
    },
    orders: {
      current: 150,
      previous: 125,
    },
    customers: {
      current: 320,
      previous: 280,
    },
    products: {
      current: 65,
      previous: 58,
    }
  }
}

export default function DashboardPage() {
  const [stats, setStats] = useState(demoData.stats)
  const [dailyOrders, setDailyOrders] = useState(demoData.dailyOrders)
  const [monthlySales, setMonthlySales] = useState(demoData.monthlySales)
  const [isLoading, setIsLoading] = useState(true)
  // Comment out Supabase client for testing
  // const supabase = createClientComponentClient()

  useEffect(() => {
    // In a real implementation, you would fetch actual data from Supabase
    // For now, we'll just simulate loading
    const fetchDashboardData = async () => {
      try {
        setIsLoading(true)
        // Simulating API call delay
        await new Promise(resolve => setTimeout(resolve, 500))
        
        // In a real implementation, this would be:
        // const { data: revenueData } = await supabase.rpc('get_revenue_stats')
        // const { data: orderData } = await supabase.rpc('get_order_stats')
        // etc.
        
        // Just using demo data for now
        setStats(demoData.stats)
        setDailyOrders(demoData.dailyOrders)
        setMonthlySales(demoData.monthlySales)
      } catch (error) {
        console.error('Error fetching dashboard data:', error)
      } finally {
        setIsLoading(false)
      }
    }
    
    fetchDashboardData()
  }, []) // Remove supabase dependency

  return (
    <div className="flex-1 space-y-4 p-4 md:p-8 pt-6">
      <div className="flex items-center justify-between">
        <h2 className="text-3xl font-bold tracking-tight">Dashboard</h2>
      </div>
      
      <Tabs defaultValue="overview" className="space-y-4">
        <TabsList>
          <TabsTrigger value="overview">Overview</TabsTrigger>
          <TabsTrigger value="analytics">Analytics</TabsTrigger>
        </TabsList>
        
        <TabsContent value="overview" className="space-y-4">
          {/* Stats Cards */}
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
            {/* Revenue Card */}
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Total Revenue</CardTitle>
                <CreditCard className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{formatCurrency(stats.revenue.current)}</div>
                <div className="flex items-center text-xs text-muted-foreground">
                  {calculatePercentChange(stats.revenue.current, stats.revenue.previous) > 0 ? (
                    <ArrowUpRight className="mr-1 h-4 w-4 text-emerald-500" />
                  ) : (
                    <ArrowDownRight className="mr-1 h-4 w-4 text-red-500" />
                  )}
                  <span 
                    className={calculatePercentChange(stats.revenue.current, stats.revenue.previous) > 0 
                      ? "text-emerald-500" 
                      : "text-red-500"
                    }
                  >
                    {Math.abs(calculatePercentChange(stats.revenue.current, stats.revenue.previous)).toFixed(1)}%
                  </span>
                  <span className="ml-1">from last month</span>
                </div>
              </CardContent>
            </Card>
            
            {/* Orders Card */}
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Orders</CardTitle>
                <ShoppingCart className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{stats.orders.current}</div>
                <div className="flex items-center text-xs text-muted-foreground">
                  {calculatePercentChange(stats.orders.current, stats.orders.previous) > 0 ? (
                    <ArrowUpRight className="mr-1 h-4 w-4 text-emerald-500" />
                  ) : (
                    <ArrowDownRight className="mr-1 h-4 w-4 text-red-500" />
                  )}
                  <span 
                    className={calculatePercentChange(stats.orders.current, stats.orders.previous) > 0 
                      ? "text-emerald-500" 
                      : "text-red-500"
                    }
                  >
                    {Math.abs(calculatePercentChange(stats.orders.current, stats.orders.previous)).toFixed(1)}%
                  </span>
                  <span className="ml-1">from last month</span>
                </div>
              </CardContent>
            </Card>
            
            {/* Customers Card */}
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Customers</CardTitle>
                <Users className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{stats.customers.current}</div>
                <div className="flex items-center text-xs text-muted-foreground">
                  {calculatePercentChange(stats.customers.current, stats.customers.previous) > 0 ? (
                    <ArrowUpRight className="mr-1 h-4 w-4 text-emerald-500" />
                  ) : (
                    <ArrowDownRight className="mr-1 h-4 w-4 text-red-500" />
                  )}
                  <span 
                    className={calculatePercentChange(stats.customers.current, stats.customers.previous) > 0 
                      ? "text-emerald-500" 
                      : "text-red-500"
                    }
                  >
                    {Math.abs(calculatePercentChange(stats.customers.current, stats.customers.previous)).toFixed(1)}%
                  </span>
                  <span className="ml-1">from last month</span>
                </div>
              </CardContent>
            </Card>
            
            {/* Products Card */}
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Products</CardTitle>
                <Package className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{stats.products.current}</div>
                <div className="flex items-center text-xs text-muted-foreground">
                  {calculatePercentChange(stats.products.current, stats.products.previous) > 0 ? (
                    <ArrowUpRight className="mr-1 h-4 w-4 text-emerald-500" />
                  ) : (
                    <ArrowDownRight className="mr-1 h-4 w-4 text-red-500" />
                  )}
                  <span 
                    className={calculatePercentChange(stats.products.current, stats.products.previous) > 0 
                      ? "text-emerald-500" 
                      : "text-red-500"
                    }
                  >
                    {Math.abs(calculatePercentChange(stats.products.current, stats.products.previous)).toFixed(1)}%
                  </span>
                  <span className="ml-1">from last month</span>
                </div>
              </CardContent>
            </Card>
          </div>
          
          {/* Charts */}
          <div className="grid gap-4 md:grid-cols-2">
            {/* Daily Orders Chart */}
            <Card>
              <CardHeader>
                <CardTitle>Daily Orders</CardTitle>
                <CardDescription>
                  Number of orders placed each day this week
                </CardDescription>
              </CardHeader>
              <CardContent>
                <div className="h-[300px]">
                  <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={dailyOrders}>
                      <CartesianGrid strokeDasharray="3 3" />
                      <XAxis dataKey="name" />
                      <YAxis />
                      <Tooltip 
                        formatter={(value) => [`${value} orders`, 'Orders']}
                        labelStyle={{ color: 'black' }}
                      />
                      <Bar dataKey="orders" fill="#3b82f6" radius={[4, 4, 0, 0]} />
                    </BarChart>
                  </ResponsiveContainer>
                </div>
              </CardContent>
            </Card>
            
            {/* Monthly Sales Chart */}
            <Card>
              <CardHeader>
                <CardTitle>Monthly Sales</CardTitle>
                <CardDescription>
                  Revenue generated each month
                </CardDescription>
              </CardHeader>
              <CardContent>
                <div className="h-[300px]">
                  <ResponsiveContainer width="100%" height="100%">
                    <LineChart data={monthlySales}>
                      <CartesianGrid strokeDasharray="3 3" />
                      <XAxis dataKey="name" />
                      <YAxis 
                        tickFormatter={(value) => formatCurrency(value).replace('₹', '')}
                      />
                      <Tooltip 
                        formatter={(value) => [formatCurrency(value), 'Sales']}
                        labelStyle={{ color: 'black' }}
                      />
                      <Line 
                        type="monotone" 
                        dataKey="sales" 
                        stroke="#3b82f6" 
                        strokeWidth={2}
                        dot={{ r: 4 }}
                        activeDot={{ r: 6 }}
                      />
                    </LineChart>
                  </ResponsiveContainer>
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>
        
        <TabsContent value="analytics" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Advanced Analytics</CardTitle>
              <CardDescription>
                Detailed analysis of sales and customer behavior
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="h-[400px] flex items-center justify-center text-muted-foreground">
                Advanced analytics will be available in the next update
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  )
} 