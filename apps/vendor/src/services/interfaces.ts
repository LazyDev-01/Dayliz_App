// Abstract interface for backend switching as outlined in the strategic roadmap
import type { 
  Order, 
  Product, 
  VendorInventory, 
  OrderFilters, 
  ProductFilters,
  DashboardStats,
  OrderTrend,
  Vendor,
  AuthUser,
  LoginCredentials,
  PaginatedResponse
} from '@/types'

/**
 * Abstract interface for vendor data service
 * This allows seamless switching between Supabase and FastAPI backends
 */
export interface VendorDataService {
  // Authentication
  login(credentials: LoginCredentials): Promise<AuthUser>
  logout(): Promise<void>
  getCurrentUser(): Promise<AuthUser | null>
  
  // Orders
  getOrders(vendorId: string, filters?: OrderFilters): Promise<PaginatedResponse<Order>>
  getOrder(orderId: string): Promise<Order>
  updateOrderStatus(orderId: string, status: string): Promise<void>
  acceptOrder(orderId: string): Promise<void>
  rejectOrder(orderId: string, reason?: string): Promise<void>
  markOrderReady(orderId: string): Promise<void>
  
  // Real-time subscriptions
  subscribeToOrders(vendorId: string, callback: (order: Order) => void): () => void
  subscribeToOrderUpdates(orderId: string, callback: (order: Order) => void): () => void
  
  // Products & Inventory
  getProducts(vendorId: string, filters?: ProductFilters): Promise<PaginatedResponse<Product>>
  getVendorInventory(vendorId: string): Promise<VendorInventory[]>
  updateInventory(inventoryId: string, updates: Partial<VendorInventory>): Promise<void>
  bulkUpdateInventory(updates: Array<{ id: string; updates: Partial<VendorInventory> }>): Promise<void>
  
  // Analytics
  getDashboardStats(vendorId: string): Promise<DashboardStats>
  getOrderTrends(vendorId: string, days: number): Promise<OrderTrend[]>
  
  // Vendor profile
  getVendorProfile(vendorId: string): Promise<Vendor>
  updateVendorProfile(vendorId: string, updates: Partial<Vendor>): Promise<void>
}

/**
 * Real-time event types for subscriptions
 */
export interface RealtimeEvent<T = any> {
  eventType: 'INSERT' | 'UPDATE' | 'DELETE'
  new: T
  old?: T
  table: string
}

/**
 * Service configuration interface
 */
export interface ServiceConfig {
  supabaseUrl?: string
  supabaseAnonKey?: string
  fastApiBaseUrl?: string
  fastApiToken?: string
  enableRealtime?: boolean
  enableOffline?: boolean
}

/**
 * Error types for service layer
 */
export class ServiceError extends Error {
  constructor(
    message: string,
    public code: string,
    public statusCode?: number
  ) {
    super(message)
    this.name = 'ServiceError'
  }
}

export class AuthError extends ServiceError {
  constructor(message: string) {
    super(message, 'AUTH_ERROR', 401)
    this.name = 'AuthError'
  }
}

export class NetworkError extends ServiceError {
  constructor(message: string) {
    super(message, 'NETWORK_ERROR', 0)
    this.name = 'NetworkError'
  }
}

export class ValidationError extends ServiceError {
  constructor(message: string) {
    super(message, 'VALIDATION_ERROR', 400)
    this.name = 'ValidationError'
  }
}
