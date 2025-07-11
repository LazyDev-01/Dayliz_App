import { createClient, SupabaseClient, RealtimeChannel } from '@supabase/supabase-js'

// Create and export a shared Supabase client for direct use
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing Supabase environment variables')
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: true
  },
  realtime: {
    params: {
      eventsPerSecond: 10
    }
  }
})
import {
  VendorDataService,
  ServiceConfig,
  AuthError,
  NetworkError
} from './interfaces'
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
 * Supabase implementation of VendorDataService
 * Implements the service layer architecture from the strategic roadmap
 */
export class SupabaseVendorService implements VendorDataService {
  private client: SupabaseClient
  private channels: Map<string, RealtimeChannel> = new Map()

  constructor(config: ServiceConfig) {
    if (!config.supabaseUrl || !config.supabaseAnonKey) {
      throw new Error('Supabase URL and anon key are required')
    }

    this.client = createClient(config.supabaseUrl, config.supabaseAnonKey, {
      auth: {
        autoRefreshToken: true,
        persistSession: true,
        detectSessionInUrl: true
      },
      realtime: {
        params: {
          eventsPerSecond: 10
        }
      }
    })
  }

  // Authentication methods
  async login(credentials: LoginCredentials): Promise<AuthUser> {
    try {
      const { data, error } = await this.client.auth.signInWithPassword({
        email: credentials.email,
        password: credentials.password
      })

      if (error) {
        throw new AuthError(error.message)
      }

      if (!data.user) {
        throw new AuthError('Login failed')
      }

      // Get vendor data from database
      const { data: vendorData, error: vendorError } = await this.client
        .from('vendors')
        .select('*')
        .eq('user_id', data.user.id)
        .eq('is_active', true)
        .limit(1)
        .maybeSingle()

      if (vendorError || !vendorData) {
        throw new AuthError('Vendor not found or inactive')
      }

      return {
        id: data.user.id,
        email: data.user.email!,
        vendor: vendorData as Vendor
      }
    } catch (error) {
      if (error instanceof AuthError) throw error
      throw new NetworkError('Login failed due to network error')
    }
  }

  async logout(): Promise<void> {
    // Clean up all subscriptions
    this.channels.forEach(channel => {
      this.client.removeChannel(channel)
    })
    this.channels.clear()

    const { error } = await this.client.auth.signOut()
    if (error) {
      throw new NetworkError('Logout failed')
    }
  }

  async getCurrentUser(): Promise<AuthUser | null> {
    const { data: { user } } = await this.client.auth.getUser()
    
    if (!user) return null

    // Get vendor data from database
    const { data: vendorData, error: vendorError } = await this.client
      .from('vendors')
      .select('*')
      .eq('user_id', user.id)
      .eq('is_active', true)
      .limit(1)
      .maybeSingle()

    if (vendorError || !vendorData) return null

    return {
      id: user.id,
      email: user.email!,
      vendor: vendorData as Vendor
    }
  }

  // Orders methods
  async getOrders(vendorId: string, filters?: OrderFilters): Promise<PaginatedResponse<Order>> {
    let query = this.client
      .from('orders')
      .select(`
        *,
        order_items(*, products(*)),
        users(name, phone, email),
        addresses(*)
      `)
      .eq('assigned_vendor_id', vendorId)
      .order('created_at', { ascending: false })

    // Apply filters
    if (filters?.status?.length) {
      query = query.in('status', filters.status)
    }
    if (filters?.date_from) {
      query = query.gte('created_at', filters.date_from)
    }
    if (filters?.date_to) {
      query = query.lte('created_at', filters.date_to)
    }
    if (filters?.min_amount) {
      query = query.gte('total_amount', filters.min_amount)
    }
    if (filters?.max_amount) {
      query = query.lte('total_amount', filters.max_amount)
    }

    const { data, error, count } = await query

    if (error) {
      throw new NetworkError('Failed to fetch orders')
    }

    return {
      data: data as Order[],
      total: count || 0,
      page: 1,
      page_size: data?.length || 0,
      has_more: false
    }
  }

  async getOrder(orderId: string): Promise<Order> {
    const { data, error } = await this.client
      .from('orders')
      .select(`
        *,
        order_items(*, products(*)),
        users(name, phone, email),
        addresses(*)
      `)
      .eq('id', orderId)
      .single()

    if (error || !data) {
      throw new NetworkError('Failed to fetch order')
    }

    return data as Order
  }

  async updateOrderStatus(orderId: string, status: string): Promise<void> {
    const updates: any = { 
      status,
      updated_at: new Date().toISOString()
    }

    // Add timestamp for specific statuses
    if (status === 'accepted') {
      updates.accepted_at = new Date().toISOString()
    } else if (status === 'preparing') {
      updates.prepared_at = new Date().toISOString()
    } else if (status === 'ready') {
      updates.ready_at = new Date().toISOString()
    }

    const { error } = await this.client
      .from('orders')
      .update(updates)
      .eq('id', orderId)

    if (error) {
      throw new NetworkError('Failed to update order status')
    }
  }

  async acceptOrder(orderId: string): Promise<void> {
    await this.updateOrderStatus(orderId, 'accepted')
  }

  async rejectOrder(orderId: string, reason?: string): Promise<void> {
    const { error } = await this.client
      .from('orders')
      .update({ 
        status: 'cancelled',
        cancellation_reason: reason || 'Rejected by vendor',
        updated_at: new Date().toISOString()
      })
      .eq('id', orderId)

    if (error) {
      throw new NetworkError('Failed to reject order')
    }
  }

  async markOrderReady(orderId: string): Promise<void> {
    await this.updateOrderStatus(orderId, 'ready')
  }

  // Real-time subscriptions
  subscribeToOrders(vendorId: string, callback: (order: Order) => void): () => void {
    const channelName = `vendor-${vendorId}-orders`
    
    const channel = this.client
      .channel(channelName)
      .on('postgres_changes', {
        event: '*',
        schema: 'public',
        table: 'orders',
        filter: `assigned_vendor_id=eq.${vendorId}`
      }, async (payload: any) => {
        // Fetch complete order data with relations
        if (payload.new) {
          try {
            const order = await this.getOrder(payload.new.id)
            callback(order)
          } catch (error) {
            console.error('Failed to fetch order for real-time update:', error)
          }
        }
      })
      .subscribe()

    this.channels.set(channelName, channel)

    // Return cleanup function
    return () => {
      this.client.removeChannel(channel)
      this.channels.delete(channelName)
    }
  }

  subscribeToOrderUpdates(orderId: string, callback: (order: Order) => void): () => void {
    const channelName = `order-${orderId}-updates`
    
    const channel = this.client
      .channel(channelName)
      .on('postgres_changes', {
        event: 'UPDATE',
        schema: 'public',
        table: 'orders',
        filter: `id=eq.${orderId}`
      }, async (payload) => {
        if (payload.new) {
          try {
            const order = await this.getOrder(payload.new.id)
            callback(order)
          } catch (error) {
            console.error('Failed to fetch order for real-time update:', error)
          }
        }
      })
      .subscribe()

    this.channels.set(channelName, channel)

    return () => {
      this.client.removeChannel(channel)
      this.channels.delete(channelName)
    }
  }

  // Products & Inventory methods (to be implemented)
  async getProducts(_vendorId: string, _filters?: ProductFilters): Promise<PaginatedResponse<Product>> {
    // Implementation will be added in next iteration
    throw new Error('Not implemented yet')
  }

  async getVendorInventory(_vendorId: string): Promise<VendorInventory[]> {
    // Implementation will be added in next iteration
    throw new Error('Not implemented yet')
  }

  async updateInventory(_inventoryId: string, _updates: Partial<VendorInventory>): Promise<void> {
    // Implementation will be added in next iteration
    throw new Error('Not implemented yet')
  }

  async bulkUpdateInventory(_updates: Array<{ id: string; updates: Partial<VendorInventory> }>): Promise<void> {
    // Implementation will be added in next iteration
    throw new Error('Not implemented yet')
  }

  // Analytics methods (to be implemented)
  async getDashboardStats(_vendorId: string): Promise<DashboardStats> {
    // Implementation will be added in next iteration
    throw new Error('Not implemented yet')
  }

  async getOrderTrends(_vendorId: string, _days: number): Promise<OrderTrend[]> {
    // Implementation will be added in next iteration
    throw new Error('Not implemented yet')
  }

  // Vendor profile methods (to be implemented)
  async getVendorProfile(_vendorId: string): Promise<Vendor> {
    // Implementation will be added in next iteration
    throw new Error('Not implemented yet')
  }

  async updateVendorProfile(_vendorId: string, _updates: Partial<Vendor>): Promise<void> {
    // Implementation will be added in next iteration
    throw new Error('Not implemented yet')
  }
}
