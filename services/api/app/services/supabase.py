from supabase import create_client, Client
from app.core.config import settings


class SupabaseClient:
    def __init__(self):
        self.url = settings.SUPABASE_URL
        self.key = settings.SUPABASE_KEY
        self.client = create_client(self.url, self.key)
        self.auth = self.client.auth
        
    async def get_user(self, user_id: str):
        """Get user by ID from Supabase"""
        try:
            response = await self.client.from_("users").select("*").eq("id", user_id).single()
            return response.data
        except Exception as e:
            # Log error
            return None
            
    async def get_user_by_email(self, email: str):
        """Get user by email from Supabase"""
        try:
            response = await self.client.from_("users").select("*").eq("email", email).single()
            return response.data
        except Exception as e:
            # Log error
            return None
    
    async def create_product(self, product_data):
        """Create a new product in Supabase"""
        try:
            response = await self.client.from_("products").insert(product_data).execute()
            return response.data[0] if response.data else None
        except Exception as e:
            # Log error
            return None
    
    async def get_products(self, page=1, page_size=20, category=None, search=None):
        """Get products with pagination and filters"""
        query = self.client.from_("products").select("*", count="exact")
        
        # Apply filters
        if category:
            query = query.eq("category", category)
        
        if search:
            query = query.ilike("name", f"%{search}%")
        
        # Apply pagination
        start = (page - 1) * page_size
        end = start + page_size - 1
        
        response = await query.order("created_at", desc=True).range(start, end).execute()
        
        return {
            "data": response.data,
            "count": response.count,
            "page": page,
            "page_size": page_size
        }
    
    async def get_cart_items(self, user_id: str):
        """Get cart items with product details for a user"""
        try:
            query = """
                SELECT 
                    c.id, c.user_id, c.product_id, c.quantity, c.created_at,
                    p.name, p.price, p.sale_price, p.image_url, p.stock
                FROM cart_items c
                JOIN products p ON c.product_id = p.id
                WHERE c.user_id = ?
            """
            response = await self.client.rpc(
                "get_cart_with_products", 
                {"user_id_param": user_id}
            ).execute()
            
            return response.data
        except Exception as e:
            # Log error
            return []
    
    async def create_order(self, order_data, order_items):
        """Create order and order items in a transaction"""
        try:
            # Start a Supabase transaction
            # Note: This is a simplified version - actual implementation would 
            # use proper Postgres transactions via Supabase functions
            
            # 1. Create order
            order_response = await self.client.from_("orders").insert(order_data).execute()
            if not order_response.data:
                return None
                
            order_id = order_response.data[0]["id"]
            
            # 2. Add order ID to items
            for item in order_items:
                item["order_id"] = order_id
            
            # 3. Create order items
            items_response = await self.client.from_("order_items").insert(order_items).execute()
            
            # 4. Get order with items
            order = await self.client.from_("orders").select("*").eq("id", order_id).single().execute()
            
            return order.data
        except Exception as e:
            # Log error
            return None
    
    async def update_order_status(self, order_id: int, status: str):
        """Update order status"""
        try:
            response = await self.client.from_("orders").update(
                {"status": status, "updated_at": "NOW()"}
            ).eq("id", order_id).execute()
            
            return response.data[0] if response.data else None
        except Exception as e:
            # Log error
            return None
    
    async def get_nearby_drivers(self, lat: float, lng: float, max_distance: float = 5.0):
        """Get drivers near a specific location"""
        try:
            # Call a Supabase function to calculate distance
            response = await self.client.rpc(
                "get_nearby_drivers",
                {
                    "lat_param": lat, 
                    "lng_param": lng, 
                    "max_distance_param": max_distance
                }
            ).execute()
            
            return response.data
        except Exception as e:
            # Log error
            return []


# Create a singleton instance
supabase_client = SupabaseClient() 