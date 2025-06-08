"use client"

import { useState, useEffect } from "react"
import { createClientComponentClient } from "@supabase/auth-helpers-nextjs"
import { PlusCircle, Pencil, Trash2, Search, Filter } from "lucide-react"
import { useRouter } from "next/navigation"
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
import { formatCurrency } from "@/lib/utils"
import { useToast } from "@/components/ui/use-toast"
import { logAdminAction } from "@/lib/admin-logs"
import { fetchProducts, fetchCategories, deleteProduct } from "@/lib/api"
import { Product, Category } from "@/types"

// Demo products data for testing
const demoProducts: Product[] = [
  {
    id: '1',
    name: 'Fresh Apples',
    description: 'Organic red apples from local farms',
    price: 3.99,
    sale_price: null,
    category_id: '1',
    subcategory_id: '11',
    main_image_url: 'https://images.unsplash.com/photo-1584306670957-acf935f5033c',
    stock_quantity: 150,
    is_featured: true,
    is_new_arrival: false,
    is_on_sale: false,
    created_at: '2023-05-10T08:00:00Z',
    updated_at: '2023-05-10T08:00:00Z'
  },
  {
    id: '2',
    name: 'Organic Bananas',
    description: 'Fresh, ripe organic bananas',
    price: 2.49,
    sale_price: 1.99,
    category_id: '1',
    subcategory_id: '11',
    main_image_url: 'https://images.unsplash.com/photo-1543218024-57a70143c369',
    stock_quantity: 200,
    is_featured: false,
    is_new_arrival: true,
    is_on_sale: true,
    created_at: '2023-05-11T09:30:00Z',
    updated_at: '2023-05-11T09:30:00Z'
  },
  {
    id: '3',
    name: 'Whole Milk',
    description: 'Farm fresh whole milk, 1 gallon',
    price: 4.29,
    sale_price: null,
    category_id: '2',
    subcategory_id: '21',
    main_image_url: 'https://images.unsplash.com/photo-1563636619-e9143da7973b',
    stock_quantity: 75,
    is_featured: false,
    is_new_arrival: false,
    is_on_sale: false,
    created_at: '2023-05-12T11:20:00Z',
    updated_at: '2023-05-12T11:20:00Z'
  }
]

// Demo categories data for testing
const demoCategories: Category[] = [
  { id: '1', name: 'Fruits & Vegetables', icon: 'apple', theme_color: '#4ade80', display_order: 1, created_at: '2023-01-01T00:00:00Z' },
  { id: '2', name: 'Dairy & Eggs', icon: 'milk', theme_color: '#60a5fa', display_order: 2, created_at: '2023-01-01T00:00:00Z' },
  { id: '3', name: 'Bakery', icon: 'bread', theme_color: '#f59e0b', display_order: 3, created_at: '2023-01-01T00:00:00Z' }
]

export default function ProductsPage() {
  const [products, setProducts] = useState<Product[]>([])
  const [categories, setCategories] = useState<Category[]>([])
  const [searchQuery, setSearchQuery] = useState("")
  const [categoryFilter, setCategoryFilter] = useState("all")
  const [isLoading, setIsLoading] = useState(true)
  const router = useRouter()
  // Comment out Supabase client for testing
  // const supabase = createClientComponentClient()
  const { toast } = useToast()

  // Fetch products and categories
  useEffect(() => {
    const fetchData = async () => {
      try {
        setIsLoading(true)
        
        // For testing, use demo data instead of Supabase
        // const productsData = await fetchProducts()
        // const categoriesData = await fetchCategories()
        
        // Simulate API delay
        await new Promise(resolve => setTimeout(resolve, 500))
        
        setProducts(demoProducts)
        setCategories(demoCategories)
      } catch (error) {
        console.error('Error fetching data:', error)
        toast({
          title: "Error fetching data",
          description: "Failed to load products and categories",
          variant: "destructive"
        })
      } finally {
        setIsLoading(false)
      }
    }
    
    fetchData()
  }, [toast])

  // Filter products based on search query and category
  const filteredProducts = products.filter(product => {
    const matchesSearch = product.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
                         product.description.toLowerCase().includes(searchQuery.toLowerCase())
    
    const matchesCategory = categoryFilter === "all" || product.category_id === categoryFilter
    
    return matchesSearch && matchesCategory
  })

  // Handle product deletion
  const handleDeleteProduct = async (productId: string, productName: string) => {
    if (window.confirm(`Are you sure you want to delete "${productName}"?`)) {
      try {
        // For testing, just remove from local state
        // await deleteProduct(productId)
        
        // Update local state
        setProducts(products.filter(p => p.id !== productId))
        
        // Log admin action - disabled for testing
        // const { data: { user } } = await supabase.auth.getUser()
        // if (user) {
        //   await logAdminAction(
        //     user.id,
        //     'delete',
        //     'product',
        //     productId,
        //     { productName }
        //   )
        // }
        
        toast({
          title: "Product deleted",
          description: `"${productName}" has been removed`,
        })
      } catch (error) {
        console.error('Error deleting product:', error)
        toast({
          title: "Error",
          description: "Failed to delete product",
          variant: "destructive"
        })
      }
    }
  }

  // Get category name by ID
  const getCategoryName = (categoryId: string) => {
    const category = categories.find(c => c.id === categoryId)
    return category ? category.name : 'Unknown'
  }

  return (
    <div className="flex-1 space-y-4 p-4 md:p-8 pt-6">
      <div className="flex items-center justify-between">
        <h2 className="text-3xl font-bold tracking-tight">Products</h2>
        <Button onClick={() => router.push('/products/new')}>
          <PlusCircle className="mr-2 h-4 w-4" /> Add Product
        </Button>
      </div>
      
      <Card>
        <CardHeader>
          <CardTitle>Product Inventory</CardTitle>
          <CardDescription>
            Manage your product catalog. Add, edit or remove products.
          </CardDescription>
        </CardHeader>
        <CardContent>
          {/* Filters */}
          <div className="flex flex-col md:flex-row gap-4 mb-6">
            <div className="relative flex-1">
              <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="Search products..."
                className="pl-8"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
              />
            </div>
            <div className="flex items-center gap-2">
              <Filter className="h-4 w-4 text-muted-foreground" />
              <Select value={categoryFilter} onValueChange={setCategoryFilter}>
                <SelectTrigger className="w-[180px]">
                  <SelectValue placeholder="Category" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Categories</SelectItem>
                  {categories.map(category => (
                    <SelectItem key={category.id} value={category.id}>
                      {category.name}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>
          
          {/* Products Table */}
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Product</TableHead>
                  <TableHead>Category</TableHead>
                  <TableHead>Price</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead className="text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {isLoading ? (
                  <TableRow>
                    <TableCell colSpan={5} className="h-24 text-center">
                      Loading products...
                    </TableCell>
                  </TableRow>
                ) : filteredProducts.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={5} className="h-24 text-center">
                      No products found.
                    </TableCell>
                  </TableRow>
                ) : (
                  filteredProducts.map(product => (
                    <TableRow key={product.id}>
                      <TableCell className="font-medium">
                        <div className="flex items-center gap-3">
                          <div className="h-10 w-10 rounded-md overflow-hidden bg-muted">
                            {product.image_url && (
                              <Image
                                src={product.image_url}
                                alt={product.name}
                                width={40}
                                height={40}
                                className="h-full w-full object-cover"
                              />
                            )}
                          </div>
                          <div>
                            <div className="font-medium">{product.name}</div>
                            <div className="text-xs text-muted-foreground truncate max-w-[200px]">
                              {product.description}
                            </div>
                          </div>
                        </div>
                      </TableCell>
                      <TableCell>{getCategoryName(product.category_id)}</TableCell>
                      <TableCell>{formatCurrency(product.price)}</TableCell>
                      <TableCell>
                        <Badge 
                          variant={product.in_stock ? "default" : "outline"} 
                          className={product.in_stock ? "bg-green-100 text-green-800 hover:bg-green-100" : "bg-red-100 text-red-800 hover:bg-red-100"}
                        >
                          {product.in_stock ? "In Stock" : "Out of Stock"}
                        </Badge>
                      </TableCell>
                      <TableCell className="text-right">
                        <div className="flex justify-end gap-2">
                          <Button
                            variant="ghost"
                            size="icon"
                            onClick={() => router.push(`/products/edit/${product.id}`)}
                          >
                            <Pencil className="h-4 w-4" />
                            <span className="sr-only">Edit</span>
                          </Button>
                          <Button
                            variant="ghost"
                            size="icon"
                            className="text-red-600"
                            onClick={() => handleDeleteProduct(product.id, product.name)}
                          >
                            <Trash2 className="h-4 w-4" />
                            <span className="sr-only">Delete</span>
                          </Button>
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