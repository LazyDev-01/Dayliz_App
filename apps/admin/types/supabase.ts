export type Database = {
  public: {
    Tables: {
      users: {
        Row: {
          id: string
          email: string
          first_name?: string
          last_name?: string
          profile_image_url?: string
          phone?: string
          is_admin: boolean
          created_at: string
        }
        Insert: {
          id?: string
          email: string
          first_name?: string
          last_name?: string
          profile_image_url?: string
          phone?: string
          is_admin?: boolean
          created_at?: string
        }
        Update: {
          email?: string
          first_name?: string
          last_name?: string
          profile_image_url?: string
          phone?: string
          is_admin?: boolean
        }
      }
      products: {
        Row: {
          id: string
          name: string
          description: string
          price: number
          image_url: string
          category_id: string
          subcategory_id?: string
          in_stock: boolean
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          name: string
          description: string
          price: number
          image_url: string
          category_id: string
          subcategory_id?: string
          in_stock?: boolean
          created_at?: string
          updated_at?: string
        }
        Update: {
          name?: string
          description?: string
          price?: number
          image_url?: string
          category_id?: string
          subcategory_id?: string
          in_stock?: boolean
          updated_at?: string
        }
      }
      categories: {
        Row: {
          id: string
          name: string
          image_url?: string
          created_at: string
        }
        Insert: {
          id?: string
          name: string
          image_url?: string
          created_at?: string
        }
        Update: {
          name?: string
          image_url?: string
        }
      }
      subcategories: {
        Row: {
          id: string
          category_id: string
          name: string
          image_url?: string
          created_at: string
        }
        Insert: {
          id?: string
          category_id: string
          name: string
          image_url?: string
          created_at?: string
        }
        Update: {
          category_id?: string
          name?: string
          image_url?: string
        }
      }
      orders: {
        Row: {
          id: string
          user_id: string
          total_amount: number
          status: 'pending' | 'packed' | 'shipped' | 'delivered' | 'cancelled'
          created_at: string
          updated_at: string
          address_id: string
          payment_method: string
          payment_status: 'pending' | 'completed' | 'failed'
        }
        Insert: {
          id?: string
          user_id: string
          total_amount: number
          status?: 'pending' | 'packed' | 'shipped' | 'delivered' | 'cancelled'
          created_at?: string
          updated_at?: string
          address_id: string
          payment_method: string
          payment_status?: 'pending' | 'completed' | 'failed'
        }
        Update: {
          status?: 'pending' | 'packed' | 'shipped' | 'delivered' | 'cancelled'
          updated_at?: string
          payment_status?: 'pending' | 'completed' | 'failed'
        }
      }
      order_items: {
        Row: {
          id: string
          order_id: string
          product_id: string
          quantity: number
          price: number
          created_at: string
        }
        Insert: {
          id?: string
          order_id: string
          product_id: string
          quantity: number
          price: number
          created_at?: string
        }
        Update: {
          quantity?: number
          price?: number
        }
      }
      admin_logs: {
        Row: {
          id: string
          admin_id: string
          action: string
          resource_type: string
          resource_id: string
          details?: any
          created_at: string
        }
        Insert: {
          id?: string
          admin_id: string
          action: string
          resource_type: string
          resource_id: string
          details?: any
          created_at?: string
        }
        Update: {
          details?: any
        }
      }
      addresses: {
        Row: {
          id: string
          user_id: string
          recipient_name: string
          recipient_phone: string
          address_type: 'home' | 'work' | 'other'
          building: string
          street: string
          landmark?: string
          is_default: boolean
          created_at: string
        }
        Insert: {
          id?: string
          user_id: string
          recipient_name: string
          recipient_phone: string
          address_type: 'home' | 'work' | 'other'
          building: string
          street: string
          landmark?: string
          is_default?: boolean
          created_at?: string
        }
        Update: {
          recipient_name?: string
          recipient_phone?: string
          address_type?: 'home' | 'work' | 'other'
          building?: string
          street?: string
          landmark?: string
          is_default?: boolean
        }
      }
    }
  }
} 