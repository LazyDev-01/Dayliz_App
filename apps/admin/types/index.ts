export interface Product {
  id: string;
  name: string;
  description: string;
  price: number;
  image_url: string;
  category_id: string;
  subcategory_id: string | null;
  in_stock: boolean;
  created_at: string;
  updated_at: string;
}

export interface Category {
  id: string;
  name: string;
  image_url?: string;
}

export interface Subcategory {
  id: string;
  name: string;
  category_id: string;
  image_url?: string;
}

export interface Order {
  id: string;
  user_id: string;
  total_amount: number;
  status: 'pending' | 'packed' | 'shipped' | 'delivered' | 'cancelled';
  created_at: string;
  updated_at: string;
  address_id: string;
  payment_method: string;
  payment_status: 'pending' | 'completed' | 'failed';
  items: OrderItem[];
}

export interface OrderItem {
  id: string;
  order_id: string;
  product_id: string;
  quantity: number;
  price: number;
  product?: Product;
}

export interface User {
  id: string;
  email: string;
  first_name?: string;
  last_name?: string;
  phone?: string;
  profile_image_url?: string;
  is_admin: boolean;
  created_at: string;
}

export interface AdminLog {
  id: string;
  admin_id: string;
  action: string;
  resource_type: string;
  resource_id: string;
  details?: any;
  created_at: string;
  admin?: User;
}

export interface Address {
  id: string;
  user_id: string;
  recipient_name: string;
  recipient_phone: string;
  address_type: 'home' | 'work' | 'other';
  building: string;
  street: string;
  landmark?: string;
  is_default: boolean;
} 