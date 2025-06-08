import { supabaseAdmin } from './supabase';
import { Product, Order, User, Category, Subcategory, AdminLog } from '../types';

// Products API
export const fetchProducts = async (): Promise<Product[]> => {
  const { data, error } = await supabaseAdmin
    .from('products')
    .select('*')
    .order('created_at', { ascending: false });

  if (error) throw error;
  return data || [];
};

export const fetchProduct = async (id: string): Promise<Product | null> => {
  const { data, error } = await supabaseAdmin
    .from('products')
    .select('*')
    .eq('id', id)
    .single();

  if (error) throw error;
  return data;
};

export const createProduct = async (product: Omit<Product, 'id' | 'created_at' | 'updated_at'>): Promise<Product> => {
  const { data, error } = await supabaseAdmin
    .from('products')
    .insert([{ ...product }])
    .select()
    .single();

  if (error) throw error;
  return data;
};

export const updateProduct = async (id: string, updates: Partial<Product>): Promise<Product> => {
  const { data, error } = await supabaseAdmin
    .from('products')
    .update({ ...updates, updated_at: new Date().toISOString() })
    .eq('id', id)
    .select()
    .single();

  if (error) throw error;
  return data;
};

export const deleteProduct = async (id: string): Promise<void> => {
  const { error } = await supabaseAdmin
    .from('products')
    .delete()
    .eq('id', id);

  if (error) throw error;
};

// Categories API
export const fetchCategories = async (): Promise<Category[]> => {
  const { data, error } = await supabaseAdmin
    .from('categories')
    .select('*')
    .order('name');

  if (error) throw error;
  return data || [];
};

export const fetchSubcategories = async (categoryId?: string): Promise<Subcategory[]> => {
  let query = supabaseAdmin
    .from('subcategories')
    .select('*')
    .order('name');
  
  if (categoryId) {
    query = query.eq('category_id', categoryId);
  }

  const { data, error } = await query;
  if (error) throw error;
  return data || [];
};

// Orders API
export const fetchOrders = async (): Promise<Order[]> => {
  const { data, error } = await supabaseAdmin
    .from('orders')
    .select(`
      *,
      items:order_items(
        *,
        product:products(*)
      )
    `)
    .order('created_at', { ascending: false });

  if (error) throw error;
  return data || [];
};

export const fetchOrder = async (id: string): Promise<Order | null> => {
  const { data, error } = await supabaseAdmin
    .from('orders')
    .select(`
      *,
      items:order_items(
        *,
        product:products(*)
      )
    `)
    .eq('id', id)
    .single();

  if (error) throw error;
  return data;
};

export const updateOrderStatus = async (id: string, status: Order['status']): Promise<Order> => {
  const { data, error } = await supabaseAdmin
    .from('orders')
    .update({ status, updated_at: new Date().toISOString() })
    .eq('id', id)
    .select()
    .single();

  if (error) throw error;
  return data;
};

// Users API
export const fetchUsers = async (): Promise<User[]> => {
  const { data, error } = await supabaseAdmin
    .from('users')
    .select('*')
    .order('created_at', { ascending: false });

  if (error) throw error;
  return data || [];
};

export const fetchUser = async (id: string): Promise<User | null> => {
  const { data, error } = await supabaseAdmin
    .from('users')
    .select('*')
    .eq('id', id)
    .single();

  if (error) throw error;
  return data;
};

// Admin Logs API
export const fetchAdminLogs = async (): Promise<AdminLog[]> => {
  const { data, error } = await supabaseAdmin
    .from('admin_logs')
    .select(`
      *,
      admin:users(*)
    `)
    .order('created_at', { ascending: false });

  if (error) throw error;
  return data || [];
};

// Storage API for image uploads
export const uploadProductImage = async (file: File): Promise<string> => {
  const fileExt = file.name.split('.').pop();
  const fileName = `${Math.random().toString(36).substring(2, 15)}.${fileExt}`;
  const filePath = `products/${fileName}`;

  const { error } = await supabaseAdmin.storage
    .from('images')
    .upload(filePath, file);

  if (error) throw error;

  const { data } = supabaseAdmin.storage
    .from('images')
    .getPublicUrl(filePath);

  return data.publicUrl;
}; 