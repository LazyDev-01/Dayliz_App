from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import Optional, List

from app.schemas.product import Product, ProductCreate, ProductUpdate, ProductListResponse
from app.api.v1.auth import get_current_user
from app.schemas.user import User
from app.services.supabase import supabase_client

router = APIRouter()


@router.get("/", response_model=ProductListResponse)
async def get_products(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    category: Optional[str] = None,
    subcategory: Optional[str] = None,
    search: Optional[str] = None,
    is_featured: Optional[bool] = None,
):
    """
    Get products with pagination and filters
    """
    try:
        # Build Supabase query
        query = {"page": page, "page_size": page_size}
        
        if category:
            query["category"] = category
            
        if search:
            query["search"] = search
            
        # Get products from Supabase
        result = await supabase_client.get_products(**query)
        
        return {
            "total": result["count"],
            "products": result["data"],
            "page": result["page"],
            "page_size": result["page_size"]
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error fetching products: {str(e)}"
        )


@router.get("/{product_id}", response_model=Product)
async def get_product(product_id: int):
    """
    Get product by ID
    """
    try:
        response = await supabase_client.client.from_("products").select("*").eq("id", product_id).single()
        
        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Product not found"
            )
            
        return response.data
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Product not found: {str(e)}"
        )


@router.post("/", response_model=Product)
async def create_product(
    product: ProductCreate, 
    current_user: User = Depends(get_current_user)
):
    """
    Create a new product (admin only)
    """
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to create products"
        )
        
    try:
        new_product = await supabase_client.create_product(product.model_dump())
        
        if not new_product:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Failed to create product"
            )
            
        return new_product
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Error creating product: {str(e)}"
        )


@router.put("/{product_id}", response_model=Product)
async def update_product(
    product_id: int,
    product_update: ProductUpdate,
    current_user: User = Depends(get_current_user)
):
    """
    Update a product (admin only)
    """
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to update products"
        )
        
    try:
        # Check if product exists
        existing = await supabase_client.client.from_("products").select("*").eq("id", product_id).single()
        
        if not existing.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Product not found"
            )
            
        # Update product
        update_data = {k: v for k, v in product_update.model_dump().items() if v is not None}
        response = await supabase_client.client.from_("products").update(
            update_data
        ).eq("id", product_id).execute()
        
        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Failed to update product"
            )
            
        return response.data[0]
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Error updating product: {str(e)}"
        ) 