import requests
import io
from PIL import Image
import pillow_avif
from supabase import create_client, Client
import uuid
import os

# Supabase configuration
SUPABASE_URL = "https://zdezerezpbeuebnompyj.supabase.co"
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_KEY")  # Service key for admin operations

def download_and_convert_image(image_url: str, product_id: str) -> str:
    """
    Download image from URL, convert to AVIF, upload to Supabase storage
    Returns the public URL of the uploaded image
    """
    try:
        # Download image
        response = requests.get(image_url, timeout=30)
        response.raise_for_status()
        
        # Open image with PIL
        image = Image.open(io.BytesIO(response.content))
        
        # Convert to RGB if necessary (AVIF doesn't support transparency)
        if image.mode in ('RGBA', 'LA', 'P'):
            background = Image.new('RGB', image.size, (255, 255, 255))
            if image.mode == 'P':
                image = image.convert('RGBA')
            background.paste(image, mask=image.split()[-1] if image.mode == 'RGBA' else None)
            image = background
        
        # Convert to AVIF
        avif_buffer = io.BytesIO()
        image.save(avif_buffer, format='AVIF', quality=85, speed=6)
        avif_buffer.seek(0)
        
        # Generate filename
        filename = f"axe-pulse-{product_id}.avif"
        storage_path = f"products/{filename}"
        
        # Upload to Supabase storage
        supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
        
        # Upload file
        result = supabase.storage.from_("product-images").upload(
            storage_path, 
            avif_buffer.getvalue(),
            file_options={"content-type": "image/avif"}
        )
        
        if result.error:
            raise Exception(f"Upload failed: {result.error}")
        
        # Get public URL
        public_url = supabase.storage.from_("product-images").get_public_url(storage_path)
        
        return public_url.data.public_url
        
    except Exception as e:
        print(f"Error processing image: {e}")
        return None

# Test the function
if __name__ == "__main__":
    image_url = "https://assets.unileversolutions.com/v1/36834399.png"
    product_id = "fe41e18e-aeff-4d09-921b-1a066a1ee52f"
    
    result = download_and_convert_image(image_url, product_id)
    print(f"Uploaded image URL: {result}")
