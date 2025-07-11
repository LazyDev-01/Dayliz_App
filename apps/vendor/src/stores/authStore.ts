import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import { supabase } from '@/services/supabase'
import type { AuthUser, LoginCredentials, Vendor } from '@/types'

interface AuthState {
  user: AuthUser | null
  vendor: Vendor | null
  isAuthenticated: boolean
  isLoading: boolean
  error: string | null
  
  // Actions
  login: (credentials: LoginCredentials) => Promise<boolean>
  logout: () => Promise<void>
  clearError: () => void
  checkAuth: () => Promise<void>
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      user: null,
      vendor: null,
      isAuthenticated: false,
      isLoading: false,
      error: null,

      login: async (credentials: LoginCredentials) => {
        set({ isLoading: true, error: null })

        try {
          // Mock successful login for testing
          const user: AuthUser = {
            id: 'test-user-id',
            email: credentials.email,
            vendor: {
              id: 'test-vendor-id',
              name: 'Test Vendor Store',
              email: credentials.email,
              status: 'active',
              vendor_type: 'external',
              operational_model: 'single_vendor',
              is_active: true,
              priority_level: 1,
              delivery_radius_km: 5,
              avg_preparation_time_minutes: 30,
              commission_rate: 0.1,
              min_order_amount: 100,
              rating: 4.5,
              total_orders: 0,
              created_at: new Date().toISOString(),
              updated_at: new Date().toISOString()
            }
          }

          set({
            user,
            vendor: user.vendor,
            isAuthenticated: true,
            isLoading: false,
            error: null
          })

          return true
        } catch (error) {
          const errorMessage = error instanceof Error ? error.message : 'Login failed. Please try again.'

          set({
            user: null,
            vendor: null,
            isAuthenticated: false,
            isLoading: false,
            error: errorMessage
          })

          return false
        }
      },

      logout: async () => {
        set({ isLoading: true })

        try {
          // await supabase.auth.signOut()
        } catch (error) {
          console.error('Logout error:', error)
        } finally {
          set({
            user: null,
            vendor: null,
            isAuthenticated: false,
            isLoading: false,
            error: null
          })
        }
      },

      clearError: () => {
        set({ error: null })
      },

      checkAuth: async () => {
        set({ isLoading: true })

        try {
          // Mock check - no existing session for now
          const user = null

          if (user) {
            set({
              user,
              vendor: user.vendor,
              isAuthenticated: true,
              isLoading: false,
              error: null
            })
          } else {
            set({
              user: null,
              vendor: null,
              isAuthenticated: false,
              isLoading: false,
              error: null
            })
          }
        } catch (error) {
          console.error('Auth check error:', error)
          set({
            user: null,
            vendor: null,
            isAuthenticated: false,
            isLoading: false,
            error: null
          })
        }
      }
    }),
    {
      name: 'vendor-auth-storage',
      partialize: (state) => ({
        user: state.user,
        vendor: state.vendor,
        isAuthenticated: state.isAuthenticated
      })
    }
  )
)

// Initialize auth check on app start (with error handling)
// Temporarily disabled to test app loading
// setTimeout(() => {
//   try {
//     useAuthStore.getState().checkAuth()
//   } catch (error) {
//     console.error('Auth initialization error:', error)
//   }
// }, 100)
