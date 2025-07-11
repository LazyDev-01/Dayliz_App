import { supabase } from './supabase'
import { Order, OrderStatus } from '@/types'

export class OrderService {
  /**
   * Get orders for the current vendor with real-time subscription
   */
  static async getVendorOrders(vendorId: string, status?: OrderStatus) {
    try {
      let query = supabase
        .from('orders')
        .select(`
          *,
          order_items (
            id,
            product_id,
            product_name,
            image_url,
            quantity,
            product_price,
            total_price,
            options,
            variant_id,
            sku
          ),
          users!orders_user_id_fkey (
            id,
            email,
            user_metadata
          )
        `)
        .eq('assigned_vendor_id', vendorId)
        .order('created_at', { ascending: false })

      if (status) {
        query = query.eq('status', status)
      }

      const { data, error } = await query

      if (error) {
        console.error('Error fetching vendor orders:', error)
        throw new Error(`Failed to fetch orders: ${error.message}`)
      }

      return data as Order[]
    } catch (error) {
      console.error('OrderService.getVendorOrders error:', error)
      throw error
    }
  }

  /**
   * Subscribe to real-time order updates for vendor
   */
  static subscribeToVendorOrders(
    vendorId: string,
    onOrderUpdate: (payload: any) => void,
    onError?: (error: any) => void
  ) {
    const subscription = supabase
      .channel('vendor-orders')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'orders',
          filter: `assigned_vendor_id=eq.${vendorId}`
        },
        onOrderUpdate
      )
      .subscribe((status) => {
        if (status === 'SUBSCRIBED') {
          console.log('✅ Subscribed to vendor orders')
        } else if (status === 'CHANNEL_ERROR') {
          console.error('❌ Failed to subscribe to vendor orders')
          onError?.(new Error('Failed to subscribe to real-time updates'))
        }
      })

    return subscription
  }

  /**
   * Update order status
   */
  static async updateOrderStatus(orderId: string, status: OrderStatus, vendorId: string) {
    try {
      const updateData: any = {
        status,
        updated_at: new Date().toISOString()
      }

      // Add timestamp fields based on status
      switch (status) {
        case 'processing':
          updateData.accepted_at = new Date().toISOString()
          break
        case 'out_for_delivery':
          updateData.ready_at = new Date().toISOString()
          break
        case 'delivered':
          updateData.delivered_at = new Date().toISOString()
          break
      }

      const { data, error } = await supabase
        .from('orders')
        .update(updateData)
        .eq('id', orderId)
        .eq('assigned_vendor_id', vendorId) // Security: only update own orders
        .select()
        .single()

      if (error) {
        console.error('Error updating order status:', error)
        throw new Error(`Failed to update order: ${error.message}`)
      }

      // Insert status history record
      await this.insertOrderStatusHistory(orderId, status, vendorId)

      return data
    } catch (error) {
      console.error('OrderService.updateOrderStatus error:', error)
      throw error
    }
  }

  /**
   * Accept an order
   */
  static async acceptOrder(orderId: string, vendorId: string) {
    return this.updateOrderStatus(orderId, 'processing', vendorId)
  }

  /**
   * Reject an order
   */
  static async rejectOrder(orderId: string, vendorId: string, reason?: string) {
    try {
      const updateData: any = {
        status: 'cancelled',
        updated_at: new Date().toISOString(),
        cancellation_reason: reason || 'Rejected by vendor'
      }

      const { data, error } = await supabase
        .from('orders')
        .update(updateData)
        .eq('id', orderId)
        .eq('assigned_vendor_id', vendorId)
        .select()
        .single()

      if (error) {
        console.error('Error rejecting order:', error)
        throw new Error(`Failed to reject order: ${error.message}`)
      }

      await this.insertOrderStatusHistory(orderId, 'cancelled', vendorId, reason)

      return data
    } catch (error) {
      console.error('OrderService.rejectOrder error:', error)
      throw error
    }
  }

  /**
   * Mark order as ready for delivery
   */
  static async markOrderReady(orderId: string, vendorId: string) {
    return this.updateOrderStatus(orderId, 'out_for_delivery', vendorId)
  }

  /**
   * Get order statistics for vendor dashboard
   */
  static async getVendorOrderStats(vendorId: string) {
    try {
      const { data, error } = await supabase
        .from('orders')
        .select('status, total_amount, created_at')
        .eq('assigned_vendor_id', vendorId)

      if (error) {
        console.error('Error fetching order stats:', error)
        throw new Error(`Failed to fetch order statistics: ${error.message}`)
      }

      const stats = {
        total: data.length,
        processing: data.filter(o => o.status === 'processing').length,
        out_for_delivery: data.filter(o => o.status === 'out_for_delivery').length,
        completed: data.filter(o => o.status === 'delivered').length,
        cancelled: data.filter(o => o.status === 'cancelled').length,
        totalRevenue: data
          .filter(o => o.status === 'delivered')
          .reduce((sum, o) => sum + parseFloat(o.total_amount || '0'), 0),
        todayOrders: data.filter(o => {
          const today = new Date().toDateString()
          return new Date(o.created_at).toDateString() === today
        }).length
      }

      return stats
    } catch (error) {
      console.error('OrderService.getVendorOrderStats error:', error)
      throw error
    }
  }

  /**
   * Insert order status history record
   */
  private static async insertOrderStatusHistory(
    orderId: string, 
    status: string, 
    vendorId: string, 
    message?: string
  ) {
    try {
      await supabase
        .from('order_status_history')
        .insert({
          order_id: orderId,
          status,
          status_message: message,
          changed_by: vendorId,
          changed_by_type: 'vendor',
          created_at: new Date().toISOString()
        })
    } catch (error) {
      console.error('Failed to insert order status history:', error)
      // Don't throw here as it's not critical for the main operation
    }
  }

  /**
   * Get single order with full details
   */
  static async getOrderById(orderId: string, vendorId: string) {
    try {
      const { data, error } = await supabase
        .from('orders')
        .select(`
          *,
          order_items (
            id,
            product_id,
            product_name,
            image_url,
            quantity,
            product_price,
            total_price,
            options,
            variant_id,
            sku
          ),
          users!orders_user_id_fkey (
            id,
            email,
            user_metadata
          )
        `)
        .eq('id', orderId)
        .eq('assigned_vendor_id', vendorId)
        .single()

      if (error) {
        console.error('Error fetching order:', error)
        throw new Error(`Failed to fetch order: ${error.message}`)
      }

      return data as Order
    } catch (error) {
      console.error('OrderService.getOrderById error:', error)
      throw error
    }
  }
}
