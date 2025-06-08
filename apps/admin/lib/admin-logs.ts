import { supabase } from './supabase'

/**
 * Log an admin action
 * @param adminId The ID of the admin user
 * @param action The action performed (e.g., 'create', 'update', 'delete')
 * @param entityType The type of entity affected (e.g., 'product', 'order', 'user')
 * @param entityId The ID of the entity affected
 * @param details Additional details about the action
 */
export async function logAdminAction(
  adminId: string,
  action: string,
  entityType: string,
  entityId: string,
  details: any = {}
) {
  try {
    await supabase.from('admin_logs').insert({
      admin_id: adminId,
      action,
      entity_type: entityType,
      entity_id: entityId,
      details,
      created_at: new Date().toISOString()
    })
  } catch (error) {
    console.error('Failed to log admin action:', error)
  }
}

/**
 * Get admin logs with pagination
 * @param page Page number (1-based)
 * @param pageSize Number of logs per page
 * @param filters Optional filters for the logs
 */
export async function getAdminLogs(
  page = 1,
  pageSize = 10,
  filters: {
    adminId?: string
    action?: string
    entityType?: string
    entityId?: string
    startDate?: string
    endDate?: string
  } = {}
) {
  try {
    let query = supabase
      .from('admin_logs')
      .select(`
        *,
        admin:admin_id(name, email)
      `)
      .order('created_at', { ascending: false })
    
    // Apply filters
    if (filters.adminId) {
      query = query.eq('admin_id', filters.adminId)
    }
    if (filters.action) {
      query = query.eq('action', filters.action)
    }
    if (filters.entityType) {
      query = query.eq('entity_type', filters.entityType)
    }
    if (filters.entityId) {
      query = query.eq('entity_id', filters.entityId)
    }
    if (filters.startDate) {
      query = query.gte('created_at', filters.startDate)
    }
    if (filters.endDate) {
      query = query.lte('created_at', filters.endDate)
    }
    
    // Apply pagination
    const from = (page - 1) * pageSize
    const to = from + pageSize - 1
    query = query.range(from, to)
    
    const { data, error, count } = await query
    
    if (error) {
      throw error
    }
    
    return {
      logs: data || [],
      totalCount: count || 0,
      page,
      pageSize,
      totalPages: count ? Math.ceil(count / pageSize) : 0
    }
  } catch (error) {
    console.error('Failed to fetch admin logs:', error)
    return {
      logs: [],
      totalCount: 0,
      page,
      pageSize,
      totalPages: 0
    }
  }
} 