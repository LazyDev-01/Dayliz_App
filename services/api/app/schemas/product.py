from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum


class SortOption(str, Enum):
    """Available sort options for products"""
    PRICE_LOW_TO_HIGH = "price_asc"
    PRICE_HIGH_TO_LOW = "price_desc"
    NAME_A_TO_Z = "name_asc"
    NAME_Z_TO_A = "name_desc"
    NEWEST_FIRST = "created_at_desc"
    OLDEST_FIRST = "created_at_asc"
    RATING_HIGH_TO_LOW = "rating_desc"
    RATING_LOW_TO_HIGH = "rating_asc"


class FilterCriteria(BaseModel):
    """Individual filter criteria"""
    type: str = Field(..., description="Type of filter (price_range, category, brand, etc.)")
    parameters: Dict[str, Any] = Field(..., description="Filter parameters")


class ProductFilterRequest(BaseModel):
    """Request model for product filtering"""
    filters: List[FilterCriteria] = Field(default=[], description="List of filter criteria")
    sort: Optional[SortOption] = Field(default=SortOption.NEWEST_FIRST, description="Sort option")
    page: int = Field(default=1, ge=1, description="Page number")
    page_size: int = Field(default=20, ge=1, le=100, description="Items per page")
    search_query: Optional[str] = Field(default=None, description="Search query")


class FilterSuggestion(BaseModel):
    """Filter suggestion for users"""
    type: str
    label: str
    value: Any
    count: Optional[int] = None


class ProductFilterResponse(BaseModel):
    """Response model for filtered products"""
    products: List['Product']
    total_count: int
    page: int
    page_size: int
    applied_filters: List[FilterCriteria]
    available_filters: List[FilterSuggestion]
    sort_option: SortOption
    performance_metrics: Optional[Dict[str, Any]] = None


class ProductBase(BaseModel):
    name: str
    description: Optional[str] = None
    price: float
    category: str
    subcategory: Optional[str] = None
    image_url: Optional[str] = None


class ProductCreate(ProductBase):
    stock: int
    is_featured: Optional[bool] = False
    sale_price: Optional[float] = None


class ProductUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    price: Optional[float] = None
    sale_price: Optional[float] = None
    stock: Optional[int] = None
    category: Optional[str] = None
    subcategory: Optional[str] = None
    image_url: Optional[str] = None
    is_featured: Optional[bool] = None
    is_active: Optional[bool] = None


class ProductInDBBase(ProductBase):
    id: int
    stock: int
    sale_price: Optional[float] = None
    is_featured: bool
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True


class Product(ProductInDBBase):
    pass


class ProductInDB(ProductInDBBase):
    pass


class ProductListResponse(BaseModel):
    total: int
    products: List[Product]
    page: int
    page_size: int