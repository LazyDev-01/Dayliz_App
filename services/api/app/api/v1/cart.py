from fastapi import APIRouter, Depends, HTTPException, status
from typing import List

from app.schemas.cart import Cart, CartItem, CartItemCreate, CartItemUpdate, CartItemWithProduct
from app.api.v1.auth import get_current_user
from app.schemas.user import User
from app.services.supabase import supabase_client

router = APIRouter()


@router.get("/", response_model=Cart)
async def get_cart(current_user: User = Depends(get_current_user)):
    """
    Get current user's cart
    """
    try:
        # Get cart items with product details
        cart_items = await supabase_client.get_cart_items(current_user.id)
        
        # Calculate total price
        total = sum(
            item["quantity"] * (item["sale_price"] if item["sale_price"] else item["price"]) 
            for item in cart_items
        )
        
        # Format response
        items = []
        for item in cart_items:
            # Create a structured response with nested product object
            cart_item = {
                "id": item["id"],
                "user_id": item["user_id"],
                "product_id": item["product_id"],
                "quantity": item["quantity"],
                "created_at": item["created_at"],
                "product": {
                    "id": item["product_id"],
                    "name": item["name"],
                    "price": item["price"],
                    "sale_price": item["sale_price"],
                    "image_url": item["image_url"],
                    "stock": item["stock"]
                }
            }
            items.append(CartItemWithProduct(**cart_item))
        
        return {"items": items, "total": total}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error fetching cart: {str(e)}"
        )


@router.post("/", response_model=CartItem)
async def add_to_cart(
    item: CartItemCreate,
    current_user: User = Depends(get_current_user)
):
    """
    Add item to cart
    """
    try:
        # Check if product exists
        product = await supabase_client.client.from_("products").select("*").eq("id", item.product_id).single()
        
        if not product.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Product not found"
            )
            
        # Check if product is in stock
        if product.data["stock"] < item.quantity:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Not enough stock available"
            )
            
        # Check if product already in cart
        existing = await supabase_client.client.from_("cart_items").select("*").eq(
            "user_id", current_user.id
        ).eq("product_id", item.product_id).single()
        
        if existing.data:
            # Update quantity
            new_quantity = existing.data["quantity"] + item.quantity
            
            if new_quantity > product.data["stock"]:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Not enough stock available"
                )
                
            response = await supabase_client.client.from_("cart_items").update(
                {"quantity": new_quantity}
            ).eq("id", existing.data["id"]).execute()
            
            return response.data[0]
        else:
            # Add new item
            cart_data = {
                "user_id": current_user.id,
                "product_id": item.product_id,
                "quantity": item.quantity
            }
            
            response = await supabase_client.client.from_("cart_items").insert(cart_data).execute()
            
            if not response.data:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Failed to add item to cart"
                )
                
            return response.data[0]
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Error adding to cart: {str(e)}"
        )


@router.put("/{cart_item_id}", response_model=CartItem)
async def update_cart_item(
    cart_item_id: int,
    item_update: CartItemUpdate,
    current_user: User = Depends(get_current_user)
):
    """
    Update cart item quantity
    """
    try:
        # Check if cart item exists and belongs to user
        cart_item = await supabase_client.client.from_("cart_items").select("*").eq(
            "id", cart_item_id
        ).eq("user_id", current_user.id).single()
        
        if not cart_item.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Cart item not found"
            )
            
        # Check if product has enough stock
        product = await supabase_client.client.from_("products").select("*").eq(
            "id", cart_item.data["product_id"]
        ).single()
        
        if item_update.quantity > product.data["stock"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Not enough stock available"
            )
            
        # Update cart item
        response = await supabase_client.client.from_("cart_items").update(
            {"quantity": item_update.quantity}
        ).eq("id", cart_item_id).execute()
        
        return response.data[0]
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Error updating cart item: {str(e)}"
        )


@router.delete("/{cart_item_id}")
async def remove_from_cart(
    cart_item_id: int,
    current_user: User = Depends(get_current_user)
):
    """
    Remove item from cart
    """
    try:
        # Check if cart item exists and belongs to user
        cart_item = await supabase_client.client.from_("cart_items").select("*").eq(
            "id", cart_item_id
        ).eq("user_id", current_user.id).single()
        
        if not cart_item.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Cart item not found"
            )
            
        # Delete cart item
        await supabase_client.client.from_("cart_items").delete().eq("id", cart_item_id).execute()
        
        return {"message": "Item removed from cart"} 
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Error removing item from cart: {str(e)}"
        ) 