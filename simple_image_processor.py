import requests
import os
from supabase import create_client

# Supabase configuration - Replace with your credentials
SUPABASE_URL = "https://your-project.supabase.co"  # Replace with your Supabase URL
SUPABASE_SERVICE_KEY = "your_supabase_service_key_here"  # Replace with your Supabase service key

def update_product_image(product_id: str, image_url: str) -> bool:
    """
    Update or insert product image in product_images table
    """
    try:
        supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)
        
        # Check if image already exists for this product
        existing = supabase.table('product_images').select('*').eq('product_id', product_id).execute()
        
        if existing.data:
            # Update existing image
            result = supabase.table('product_images').update({
                'image_url': image_url,
                'is_primary': True
            }).eq('product_id', product_id).execute()
            print(f"Updated existing image for product: {product_id}")
        else:
            # Insert new image
            result = supabase.table('product_images').insert({
                'product_id': product_id,
                'image_url': image_url,
                'is_primary': True,
                'display_order': 1
            }).execute()
            print(f"Inserted new image for product: {product_id}")
        
        if result.error:
            print(f"Database update error: {result.error}")
            return False
            
        print(f"Successfully updated product_images table for product: {product_id}")
        return True
        
    except Exception as e:
        print(f"Error updating database: {e}")
        return False

def test_image_url_accessibility(image_url: str) -> bool:
    """
    Test if image URL is accessible
    """
    try:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }
        response = requests.head(image_url, timeout=10, headers=headers)
        return response.status_code == 200
    except:
        return False

# Test function
if __name__ == "__main__":
    # Test with AXE Pulse product
    test_product_id = "fe41e18e-aeff-4d09-921b-1a066a1ee52f"
    test_image_url = "https://assets.unileversolutions.com/v1/36834399.png"
    
    print(f"Testing image URL: {test_image_url}")
    if test_image_url_accessibility(test_image_url):
        print("Image URL is accessible")
        success = update_product_image(test_product_id, test_image_url)
        print(f"Database update {'successful' if success else 'failed'}")
    else:
        print("Image URL is not accessible, using original URL anyway")
        success = update_product_image(test_product_id, test_image_url)
        print(f"Database update {'successful' if success else 'failed'}")
