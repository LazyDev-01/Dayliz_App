import requests
import json

# Supabase configuration
SUPABASE_URL = "https://zdezerezpbeuebnompyj.supabase.co"
SUPABASE_SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpkZXplcmV6cGJldWVibm9tcHlqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0NDIwMjcwOCwiZXhwIjoyMDU5Nzc4NzA4fQ.r2zsrRbhhc2w97je_7h9vIAchykCcNlviY_P-9aQoCE"

def update_product_image_direct(product_id: str, image_url: str) -> bool:
    """
    Update or insert product image using direct REST API calls
    """
    try:
        headers = {
            'apikey': SUPABASE_SERVICE_KEY,
            'Authorization': f'Bearer {SUPABASE_SERVICE_KEY}',
            'Content-Type': 'application/json',
            'Prefer': 'return=representation'
        }
        
        # Check if image already exists for this product
        check_url = f"{SUPABASE_URL}/rest/v1/product_images?product_id=eq.{product_id}"
        check_response = requests.get(check_url, headers=headers)
        
        if check_response.status_code == 200:
            existing_data = check_response.json()
            
            if existing_data:
                # Update existing image
                update_url = f"{SUPABASE_URL}/rest/v1/product_images?product_id=eq.{product_id}"
                update_data = {
                    'image_url': image_url,
                    'is_primary': True
                }
                
                response = requests.patch(update_url, headers=headers, json=update_data)
                print(f"Updated existing image for product: {product_id}")
            else:
                # Insert new image
                insert_url = f"{SUPABASE_URL}/rest/v1/product_images"
                insert_data = {
                    'product_id': product_id,
                    'image_url': image_url,
                    'is_primary': True,
                    'display_order': 1
                }
                
                response = requests.post(insert_url, headers=headers, json=insert_data)
                print(f"Inserted new image for product: {product_id}")
            
            if response.status_code in [200, 201]:
                print(f"Successfully updated product_images table for product: {product_id}")
                return True
            else:
                print(f"Database update error: {response.status_code} - {response.text}")
                return False
        else:
            print(f"Error checking existing data: {check_response.status_code} - {check_response.text}")
            return False
            
    except Exception as e:
        print(f"Error updating database: {e}")
        return False

# Test function
if __name__ == "__main__":
    # Test with AXE Pulse product
    test_product_id = "fe41e18e-aeff-4d09-921b-1a066a1ee52f"
    test_image_url = "https://assets.unileversolutions.com/v1/36834399.png"
    
    print(f"Updating product image for: {test_product_id}")
    print(f"Image URL: {test_image_url}")
    
    success = update_product_image_direct(test_product_id, test_image_url)
    print(f"Database update {'successful' if success else 'failed'}")
