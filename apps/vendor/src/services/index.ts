import type { VendorDataService, ServiceConfig } from './interfaces'
import { SupabaseVendorService } from './supabase'

/**
 * Service factory for creating the appropriate vendor data service
 * This enables seamless switching between Supabase and FastAPI backends
 * as outlined in the strategic roadmap
 */

// Environment configuration
const config: ServiceConfig = {
  supabaseUrl: import.meta.env.VITE_SUPABASE_URL,
  supabaseAnonKey: import.meta.env.VITE_SUPABASE_ANON_KEY,
  fastApiBaseUrl: import.meta.env.VITE_FASTAPI_BASE_URL,
  fastApiToken: import.meta.env.VITE_FASTAPI_TOKEN,
  enableRealtime: import.meta.env.VITE_ENABLE_REALTIME !== 'false',
  enableOffline: import.meta.env.VITE_ENABLE_OFFLINE === 'true'
}

/**
 * Create vendor data service based on environment configuration
 * Defaults to Supabase for Phase 1, will switch to FastAPI in Phase 2
 */
function createVendorDataService(): VendorDataService {
  const backendType = import.meta.env.VITE_BACKEND_TYPE || 'supabase'
  
  switch (backendType) {
    case 'fastapi':
      // FastAPI implementation will be added in Phase 2
      throw new Error('FastAPI service not implemented yet')
    
    case 'supabase':
    default:
      return new SupabaseVendorService(config)
  }
}

// Export singleton instance
export const vendorDataService = createVendorDataService()

// Export types and interfaces
export type { VendorDataService, ServiceConfig } from './interfaces'
export { ServiceError, AuthError, NetworkError, ValidationError } from './interfaces'

// Export service classes for testing
export { SupabaseVendorService } from './supabase'
