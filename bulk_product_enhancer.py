import requests
import json
import time
from urllib.parse import quote

# Configuration - Replace with your credentials
SUPABASE_URL = "https://your-project.supabase.co"  # Replace with your Supabase URL
SUPABASE_SERVICE_KEY = "your_supabase_service_key_here"  # Replace with your Supabase service key
FIRECRAWL_API_KEY = "fc-your-api-key"  # This will be set by the MCP

def get_products_to_enhance(limit=50):
    """Get first 50 products from database"""
    try:
        headers = {
            'apikey': SUPABASE_SERVICE_KEY,
            'Authorization': f'Bearer {SUPABASE_SERVICE_KEY}',
            'Content-Type': 'application/json'
        }
        
        url = f"{SUPABASE_URL}/rest/v1/products?is_active=eq.true&limit={limit}"
        response = requests.get(url, headers=headers)
        
        if response.status_code == 200:
            return response.json()
        else:
            print(f"Error fetching products: {response.status_code} - {response.text}")
            return []
            
    except Exception as e:
        print(f"Error fetching products: {e}")
        return []

def search_product_with_firecrawl(product_name, brand):
    """Search for product using Firecrawl"""
    try:
        # This would use the Firecrawl MCP in the actual implementation
        # For now, return a placeholder structure
        search_query = f"{brand} {product_name} specifications ingredients"
        
        # Placeholder data structure that would come from Firecrawl
        return {
            'description': f"Premium {brand} {product_name} with advanced formulation",
            'specifications': {
                'brand': brand,
                'product_type': 'Consumer Product',
                'usage_instructions': 'Use as directed on package'
            },
            'image_url': f"https://via.placeholder.com/300x300/f0f0f0/666666?text={quote(brand)}+{quote(product_name[:20])}",
            'nutritional_info': None  # Only for food products
        }
        
    except Exception as e:
        print(f"Error searching with Firecrawl: {e}")
        return None

def update_product_data(product_id, description, specifications, brand):
    """Update product with enhanced data"""
    try:
        headers = {
            'apikey': SUPABASE_SERVICE_KEY,
            'Authorization': f'Bearer {SUPABASE_SERVICE_KEY}',
            'Content-Type': 'application/json',
            'Prefer': 'return=representation'
        }
        
        update_data = {
            'description': description,
            'attributes': specifications,
            'brand': brand
        }
        
        url = f"{SUPABASE_URL}/rest/v1/products?id=eq.{product_id}"
        response = requests.patch(url, headers=headers, json=update_data)
        
        return response.status_code in [200, 204]
        
    except Exception as e:
        print(f"Error updating product: {e}")
        return False

def update_product_image(product_id, image_url):
    """Update or insert product image"""
    try:
        headers = {
            'apikey': SUPABASE_SERVICE_KEY,
            'Authorization': f'Bearer {SUPABASE_SERVICE_KEY}',
            'Content-Type': 'application/json',
            'Prefer': 'return=representation'
        }
        
        # Check if image exists
        check_url = f"{SUPABASE_URL}/rest/v1/product_images?product_id=eq.{product_id}"
        check_response = requests.get(check_url, headers=headers)
        
        if check_response.status_code == 200:
            existing_data = check_response.json()
            
            if existing_data:
                # Update existing
                update_url = f"{SUPABASE_URL}/rest/v1/product_images?product_id=eq.{product_id}"
                update_data = {'image_url': image_url, 'is_primary': True}
                response = requests.patch(update_url, headers=headers, json=update_data)
            else:
                # Insert new
                insert_url = f"{SUPABASE_URL}/rest/v1/product_images"
                insert_data = {
                    'product_id': product_id,
                    'image_url': image_url,
                    'is_primary': True,
                    'display_order': 1
                }
                response = requests.post(insert_url, headers=headers, json=insert_data)
            
            return response.status_code in [200, 201]
        
        return False
        
    except Exception as e:
        print(f"Error updating image: {e}")
        return False

def enhance_product(product):
    """Enhance a single product"""
    try:
        product_id = product['id']
        product_name = product['name'] or product.get('product_name', '')
        brand = product.get('brand', '')
        current_description = product.get('description', '')
        
        print(f"\n🔄 Processing: {brand} {product_name}")
        
        # Skip if already has description
        if current_description and len(current_description.strip()) > 10:
            print(f"   ⏭️  Already has description, skipping...")
            return True
        
        # Search for enhanced data
        enhanced_data = search_product_with_firecrawl(product_name, brand)
        
        if not enhanced_data:
            print(f"   ❌ No enhanced data found")
            return False
        
        # Update product data
        success = update_product_data(
            product_id,
            enhanced_data['description'],
            enhanced_data['specifications'],
            brand
        )
        
        if success:
            print(f"   ✅ Updated product data")
        else:
            print(f"   ❌ Failed to update product data")
            return False
        
        # Update image
        if enhanced_data['image_url']:
            image_success = update_product_image(product_id, enhanced_data['image_url'])
            if image_success:
                print(f"   ✅ Updated product image")
            else:
                print(f"   ⚠️  Failed to update image")
        
        return True
        
    except Exception as e:
        print(f"   ❌ Error enhancing product: {e}")
        return False

def main():
    """Main bulk enhancement function"""
    print("🚀 Starting bulk product enhancement...")
    
    # Get products to enhance
    products = get_products_to_enhance(50)
    
    if not products:
        print("❌ No products found to enhance")
        return
    
    print(f"📦 Found {len(products)} products to enhance")
    
    success_count = 0
    failed_count = 0
    
    for i, product in enumerate(products, 1):
        print(f"\n📊 Progress: {i}/{len(products)}")
        
        if enhance_product(product):
            success_count += 1
        else:
            failed_count += 1
        
        # Rate limiting
        time.sleep(1)
    
    print(f"\n🎯 Enhancement Complete!")
    print(f"   ✅ Successful: {success_count}")
    print(f"   ❌ Failed: {failed_count}")
    print(f"   📊 Success Rate: {(success_count/(success_count+failed_count)*100):.1f}%")

if __name__ == "__main__":
    main()
