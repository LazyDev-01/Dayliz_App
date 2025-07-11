import { createClient } from '@supabase/supabase-js'
import { Database } from '../types/supabase'

// Create a more comprehensive mock client
const mockSupabaseOperations = {
  from: () => ({
    select: () => ({
      eq: () => ({
        single: () => Promise.resolve({ data: null, error: null }),
        range: () => Promise.resolve({ data: [], error: null, count: 0 }),
        order: () => Promise.resolve({ data: [], error: null }),
      }),
      order: () => Promise.resolve({ data: [], error: null }),
      range: () => Promise.resolve({ data: [], error: null, count: 0 }),
      gte: () => ({
        lte: () => Promise.resolve({ data: [], error: null }),
      }),
    }),
    insert: () => ({
      select: () => ({
        single: () => Promise.resolve({ data: {}, error: null }),
      }),
    }),
    update: () => ({
      eq: () => ({
        select: () => ({
          single: () => Promise.resolve({ data: {}, error: null }),
        }),
      }),
    }),
    delete: () => ({
      eq: () => Promise.resolve({ error: null }),
    }),
  }),
  storage: {
    from: () => ({
      upload: () => Promise.resolve({ data: {}, error: null }),
      getPublicUrl: () => ({ data: { publicUrl: 'https://example.com/image.jpg' } }),
    }),
  },
  auth: {
    getUser: () => Promise.resolve({ data: { user: { id: 'test-user-id', email: 'test@example.com' } }, error: null }),
    signOut: () => Promise.resolve({ error: null }),
    signInWithPassword: ({ email, password }: { email: string, password: string }) => {
      // Simple mock implementation that accepts any credentials
      return Promise.resolve({ 
        data: { user: { id: 'test-user-id', email }, session: {} },
        error: null 
      });
    },
    getSession: () => Promise.resolve({ 
      data: { session: { user: { id: 'test-user-id', email: 'test@example.com' } } }, 
      error: null 
    }),
  },
  rpc: () => Promise.resolve({ data: [], error: null }),
};

// Export a mock version directly for use in createClientComponentClient
export const mockSupabaseClient = mockSupabaseOperations;

// Determine if we're in a browser environment
const isBrowser = typeof window !== 'undefined';

// Helper function to check if needed env vars exist
const hasRequiredEnvVars = () => {
  return process.env.NEXT_PUBLIC_SUPABASE_URL && 
         process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
};

// Use mock data in development or when credentials are missing, real data in production with credentials
export const supabase = isBrowser && hasRequiredEnvVars() && process.env.NODE_ENV === 'production'
  ? createClient<Database>(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
    )
  : mockSupabaseOperations as any;

// Create an admin client for server-side operations
export const supabaseAdmin = isBrowser && hasRequiredEnvVars() && process.env.NODE_ENV === 'production'
  ? createClient<Database>(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false
        }
      }
    )
  : mockSupabaseOperations as any;

// Types for our Supabase tables
export type Tables = {
  users: {
    id: string
    email: string
    name: string
    profile_image_url?: string
    phone?: string
    is_admin: boolean
    created_at: string
  }
  products: {
    id: string
    name: string
    description: string
    price: number
    sale_price?: number
    category_id: string
    subcategory_id?: string
    main_image_url: string
    additional_images?: string[]
    stock_quantity: number
    is_featured: boolean
    is_new_arrival: boolean
    is_on_sale: boolean
    created_at: string
    updated_at: string
  }
  categories: {
    id: string
    name: string
    icon: string
    theme_color: string
    image_url?: string
    display_order: number
    created_at: string
  }
  subcategories: {
    id: string
    category_id: string
    name: string
    image_url?: string
    display_order: number
    created_at: string
  }
  orders: {
    id: string
    user_id: string
    status: 'processing' | 'packed' | 'out_for_delivery' | 'delivered' | 'cancelled' | 'refunded'
    total: number
    subtotal: number
    tax: number
    shipping: number
    shipping_address_id: string
    payment_method: string
    created_at: string
    updated_at: string
  }
  order_items: {
    id: string
    order_id: string
    product_id: string
    quantity: number
    price: number
    total: number
    created_at: string
  }
  admin_logs: {
    id: string
    admin_id: string
    action: string
    entity_type: string
    entity_id: string
    details: any
    created_at: string
  }
} 