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
    
    async def create_order(self, order_data, order_items=None):
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

            # 2. Add order ID to items if provided
            if order_items:
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

    # Payment-related methods
    async def create_payment_order(self, payment_data):
        """Create payment order record"""
        try:
            response = await self.client.from_("payment_orders").insert(payment_data).execute()
            return response.data[0] if response.data else None
        except Exception as e:
            print(f"Error creating payment order: {e}")
            return None

    async def get_payment_order(self, razorpay_order_id: str, user_id: str):
        """Get payment order by Razorpay order ID and user ID"""
        try:
            response = await self.client.from_("payment_orders").select("*").eq("razorpay_order_id", razorpay_order_id).eq("user_id", user_id).single().execute()
            return response.data
        except Exception as e:
            print(f"Error getting payment order: {e}")
            return None

    async def update_payment_order(self, razorpay_order_id: str, update_data):
        """Update payment order"""
        try:
            response = await self.client.from_("payment_orders").update(update_data).eq("razorpay_order_id", razorpay_order_id).execute()
            return response.data[0] if response.data else None
        except Exception as e:
            print(f"Error updating payment order: {e}")
            return None

    async def update_order_payment_status(self, order_id: str, payment_status: str, payment_id: str = None):
        """Update order payment status"""
        try:
            update_data = {"payment_status": payment_status}
            if payment_id:
                update_data["payment_id"] = payment_id

            response = await self.client.from_("orders").update(update_data).eq("id", order_id).execute()
            return response.data[0] if response.data else None
        except Exception as e:
            print(f"Error updating order payment status: {e}")
            return None

    async def create_payment_log(self, log_data):
        """Create payment log entry"""
        try:
            response = await self.client.from_("payment_logs").insert(log_data).execute()
            return response.data[0] if response.data else None
        except Exception as e:
            print(f"Error creating payment log: {e}")
            return None

    # Order management methods
    async def get_order(self, order_id: str, user_id: str):
        """Get order by ID and user ID"""
        try:
            response = await self.client.from_("orders").select("*").eq("id", order_id).eq("user_id", user_id).single().execute()
            return response.data
        except Exception as e:
            print(f"Error getting order: {e}")
            return None

    async def get_user_orders(self, user_id: str, skip: int = 0, limit: int = 20, status_filter: str = None):
        """Get user orders with pagination"""
        try:
            query = self.client.from_("orders").select("*").eq("user_id", user_id).order("created_at", desc=True).range(skip, skip + limit - 1)

            if status_filter:
                query = query.eq("status", status_filter)

            response = await query.execute()
            return response.data
        except Exception as e:
            print(f"Error getting user orders: {e}")
            return []

    async def get_user_orders_count(self, user_id: str, status_filter: str = None):
        """Get total count of user orders"""
        try:
            query = self.client.from_("orders").select("id", count="exact").eq("user_id", user_id)

            if status_filter:
                query = query.eq("status", status_filter)

            response = await query.execute()
            return response.count
        except Exception as e:
            print(f"Error getting user orders count: {e}")
            return 0

    async def get_order_with_items(self, order_id: str, user_id: str):
        """Get order with items"""
        try:
            response = await self.client.from_("orders").select("*, order_items(*)").eq("id", order_id).eq("user_id", user_id).single().execute()
            return response.data
        except Exception as e:
            print(f"Error getting order with items: {e}")
            return None

    async def update_order(self, order_id: str, update_data):
        """Update order"""
        try:
            response = await self.client.from_("orders").update(update_data).eq("id", order_id).execute()
            return response.data[0] if response.data else None
        except Exception as e:
            print(f"Error updating order: {e}")
            return None

    async def get_order_tracking(self, order_id: str, user_id: str):
        """Get order tracking information"""
        try:
            response = await self.client.from_("order_tracking").select("*").eq("order_id", order_id).eq("user_id", user_id).execute()
            return response.data
        except Exception as e:
            print(f"Error getting order tracking: {e}")
            return None

    # Driver management methods
    async def get_drivers(self, skip: int = 0, limit: int = 20, status_filter: str = None, zone_id: str = None):
        """Get drivers with pagination and filtering"""
        try:
            query = self.client.from_("drivers").select("*").order("created_at", desc=True).range(skip, skip + limit - 1)

            if status_filter:
                query = query.eq("status", status_filter)
            if zone_id:
                query = query.eq("zone_id", zone_id)

            response = await query.execute()
            return response.data
        except Exception as e:
            print(f"Error getting drivers: {e}")
            return []

    async def get_drivers_count(self, status_filter: str = None, zone_id: str = None):
        """Get total count of drivers"""
        try:
            query = self.client.from_("drivers").select("id", count="exact")

            if status_filter:
                query = query.eq("status", status_filter)
            if zone_id:
                query = query.eq("zone_id", zone_id)

            response = await query.execute()
            return response.count
        except Exception as e:
            print(f"Error getting drivers count: {e}")
            return 0

    async def get_driver(self, driver_id: str):
        """Get driver by ID"""
        try:
            response = await self.client.from_("drivers").select("*").eq("id", driver_id).single().execute()
            return response.data
        except Exception as e:
            print(f"Error getting driver: {e}")
            return None

    async def create_driver(self, driver_data):
        """Create new driver"""
        try:
            response = await self.client.from_("drivers").insert(driver_data).execute()
            return response.data[0] if response.data else None
        except Exception as e:
            print(f"Error creating driver: {e}")
            return None

    async def update_driver(self, driver_id: str, update_data):
        """Update driver"""
        try:
            response = await self.client.from_("drivers").update(update_data).eq("id", driver_id).execute()
            return response.data[0] if response.data else None
        except Exception as e:
            print(f"Error updating driver: {e}")
            return None

    async def update_driver_location(self, driver_id: str, location_data):
        """Update driver location"""
        try:
            response = await self.client.from_("driver_locations").upsert(location_data).execute()
            return response.data[0] if response.data else None
        except Exception as e:
            print(f"Error updating driver location: {e}")
            return None

    async def get_driver_orders(self, driver_id: str, skip: int = 0, limit: int = 20, status_filter: str = None):
        """Get orders assigned to driver"""
        try:
            query = self.client.from_("orders").select("*").eq("driver_id", driver_id).order("created_at", desc=True).range(skip, skip + limit - 1)

            if status_filter:
                query = query.eq("status", status_filter)

            response = await query.execute()
            return response.data
        except Exception as e:
            print(f"Error getting driver orders: {e}")
            return []

    async def get_driver_orders_count(self, driver_id: str, status_filter: str = None):
        """Get total count of driver orders"""
        try:
            query = self.client.from_("orders").select("id", count="exact").eq("driver_id", driver_id)

            if status_filter:
                query = query.eq("status", status_filter)

            response = await query.execute()
            return response.count
        except Exception as e:
            print(f"Error getting driver orders count: {e}")
            return 0


# Create a singleton instance
supabase_client = SupabaseClient() 