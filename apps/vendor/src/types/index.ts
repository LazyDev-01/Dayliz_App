// Core types for the vendor panel
export interface Vendor {
  id: string
  name: string
  email: string
  phone?: string
  status: 'active' | 'inactive' | 'suspended'
  vendor_type: 'external' | 'dark_store'
  operational_model: 'single_vendor' | 'multi_vendor' | 'hybrid' | 'dark_store_only'
  is_active: boolean
  priority_level: number
  operational_hours?: Record<string, { open: string; close: string }>
  delivery_radius_km: number
  avg_preparation_time_minutes: number
  commission_rate: number
  min_order_amount: number
  rating: number
  total_orders: number
  last_order_date?: string
  created_at: string
  updated_at: string
}

export interface Order {
  id: string
  user_id: string
  status: OrderStatus
  total_amount: number
  shipping_address: Address
  billing_address?: Address
  payment_method: 'cashOnDelivery' | 'razorpay'
  payment_status: 'pending' | 'completed' | 'failed' | 'refunded'
  tracking_number?: string
  cancellation_reason?: string
  refund_amount?: number
  address_lat?: number
  address_lng?: number
  driver_id?: string
  delivered_at?: string
  created_at: string
  updated_at: string
  accepted_at?: string
  prepared_at?: string
  ready_at?: string
  assigned_vendor_id?: string
  order_items: OrderItem[]
  user?: {
    name?: string
    phone?: string
    email?: string
  }
}

export type OrderStatus =
  | 'processing'
  | 'out_for_delivery'
  | 'delivered'
  | 'cancelled'
  | 'refunded'

export interface OrderItem {
  id: string
  order_id?: string
  product_id: string
  product_name: string
  image_url?: string
  quantity: number
  product_price: number
  total_price: number
  options?: Record<string, any>
  variant_id?: string
  sku?: string
  product?: Product
}

export interface Product {
  id: string
  name: string
  description?: string
  price: number
  discount_price?: number
  image_url?: string
  additional_images?: string[]
  is_in_stock: boolean
  stock_quantity: number
  category_id: string
  subcategory_id?: string
  brand?: string
  attributes?: Record<string, any>
  is_featured: boolean
  is_on_sale: boolean
  rating?: number
  review_count?: number
  created_at: string
  updated_at: string
}

export interface Address {
  id?: string
  user_id?: string
  type?: 'home' | 'work' | 'other'
  house_number?: string
  street?: string
  area?: string
  city: string
  state: string
  pincode: string
  country: string
  latitude?: number
  longitude?: number
  is_default?: boolean
  created_at?: string
  updated_at?: string
}

export interface VendorInventory {
  id: string
  vendor_id: string
  product_id: string
  zone_id?: string
  stock_quantity: number
  reserved_quantity: number
  reorder_level: number
  max_stock_level: number
  cost_price?: number
  selling_price?: number
  discount_price?: number
  is_available: boolean
  availability_reason?: string
  last_restocked_at?: string
  updated_at: string
  created_at: string
  product?: Product
}

// Auth types
export interface AuthUser {
  id: string
  email: string
  vendor?: Vendor
}

export interface LoginCredentials {
  email: string
  password: string
}

// API Response types
export interface ApiResponse<T> {
  data: T
  error?: string
  message?: string
}

export interface PaginatedResponse<T> {
  data: T[]
  total: number
  page: number
  page_size: number
  has_more: boolean
}

// Notification types
export interface OrderNotification {
  id: string
  order_id: string
  type: 'new_order' | 'order_update' | 'order_cancelled'
  title: string
  message: string
  read: boolean
  created_at: string
}

// Dashboard analytics types
export interface DashboardStats {
  total_orders: number
  processing_orders: number
  completed_orders: number
  total_revenue: number
  avg_order_value: number
  avg_preparation_time: number
  order_acceptance_rate: number
}

export interface OrderTrend {
  date: string
  orders: number
  revenue: number
}

// Filter and search types
export interface OrderFilters {
  status?: OrderStatus[]
  date_from?: string
  date_to?: string
  min_amount?: number
  max_amount?: string
  search?: string
}

export interface ProductFilters {
  category_id?: string
  subcategory_id?: string
  is_in_stock?: boolean
  is_featured?: boolean
  search?: string
}
