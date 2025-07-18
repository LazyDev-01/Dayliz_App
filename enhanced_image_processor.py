import requests
import io
import os
import uuid
from urllib.parse import urlparse
from supabase import create_client, Client

# Supabase configuration
SUPABASE_URL = "https://zdezerezpbeuebnompyj.supabase.co"
SUPABASE_SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpkZXplcmV6cGJldWVibm9tcHlqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0NDIwMjcwOCwiZXhwIjoyMDU5Nzc4NzA4fQ.r2zsrRbhhc2w97je_7h9vIAchykCcNlviY_P-9aQoCE"

def download_and_store_image(image_url: str, product_id: str, product_name: str = "") -> str:
    """
    Download image from URL and upload to Supabase storage
    Returns the public URL of the uploaded image
    """
    try:
        print(f"Processing image for product: {product_name}")
        print(f"Image URL: {image_url}")
        
        # Download image
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }
        response = requests.get(image_url, timeout=30, headers=headers)
        response.raise_for_status()
        
        print(f"Downloaded image: {len(response.content)} bytes")
        
        # Get file extension from URL or default to jpg
        parsed_url = urlparse(image_url)
        file_extension = os.path.splitext(parsed_url.path)[1]
        if not file_extension:
            file_extension = '.jpg'
        
        # Generate filename
        safe_product_name = "".join(c for c in product_name if c.isalnum() or c in (' ', '-', '_')).rstrip()
        safe_product_name = safe_product_name.replace(' ', '-').lower()[:50]  # Limit length
        
        filename = f"{safe_product_name}-{product_id[:8]}{file_extension}"
        storage_path = f"products/{filename}"
        
        print(f"Uploading to: {storage_path}")
        
        # Upload to Supabase storage
        supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)
        
        # Upload file to 'products' bucket
        result = supabase.storage.from_("products").upload(
            storage_path, 
            response.content,
            file_options={"content-type": f"image/{file_extension[1:]}"}
        )
        
        if result.error:
            print(f"Upload error: {result.error}")
            return image_url  # Return original URL if upload fails
        
        # Get public URL
        public_url_result = supabase.storage.from_("products").get_public_url(storage_path)
        public_url = public_url_result.data.public_url if hasattr(public_url_result, 'data') else public_url_result
        
        print(f"Successfully uploaded to: {public_url}")
        return public_url
        
    except Exception as e:
        print(f"Error processing image: {e}")
        return image_url  # Return original URL if processing fails

def update_product_image(product_id: str, image_url: str) -> bool:
    """
    Update or insert product image in product_images table
    """
    try:
        supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)
        
        # Check if image already exists for this product
        existing = supabase.table('product_images').select('*').eq('product_id', product_id).execute()
        
        if existing.data:
            # Update existing image
            result = supabase.table('product_images').update({
                'image_url': image_url,
                'is_primary': True
            }).eq('product_id', product_id).execute()
        else:
            # Insert new image
            result = supabase.table('product_images').insert({
                'product_id': product_id,
                'image_url': image_url,
                'is_primary': True,
                'display_order': 1
            }).execute()
        
        if result.error:
            print(f"Database update error: {result.error}")
            return False
            
        print(f"Successfully updated product_images table for product: {product_id}")
        return True
        
    except Exception as e:
        print(f"Error updating database: {e}")
        return False

def process_product_image(product_id: str, image_url: str, product_name: str = "") -> bool:
    """
    Complete image processing pipeline: download, store, and update database
    """
    try:
        # Download and store image
        stored_url = download_and_store_image(image_url, product_id, product_name)
        
        # Update database
        success = update_product_image(product_id, stored_url)
        
        return success
        
    except Exception as e:
        print(f"Error in image processing pipeline: {e}")
        return False

# Test function
if __name__ == "__main__":
    # Test with AXE Pulse product
    test_product_id = "fe41e18e-aeff-4d09-921b-1a066a1ee52f"
    test_image_url = "https://assets.unileversolutions.com/v1/36834399.png"
    test_product_name = "AXE Pulse bodyspray Deodorant"
    
    success = process_product_image(test_product_id, test_image_url, test_product_name)
    print(f"Image processing {'successful' if success else 'failed'}")
