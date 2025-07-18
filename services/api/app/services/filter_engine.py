"""
Enterprise-grade filter engine for product filtering and sorting.
Designed to be extensible and serve all apps in the platform.
"""

from typing import List, Dict, Any, Optional, Tuple
from datetime import datetime
import time
from abc import ABC, abstractmethod

from app.schemas.product import FilterCriteria, SortOption, FilterSuggestion, ProductFilterResponse
from app.services.supabase import SupabaseClient


class FilterPlugin(ABC):
    """Abstract base class for filter plugins"""
    
    @property
    @abstractmethod
    def filter_type(self) -> str:
        """Return the filter type identifier"""
        pass
    
    @abstractmethod
    def apply_filter(self, query, criteria: FilterCriteria):
        """Apply the filter to the Supabase query"""
        pass
    
    @abstractmethod
    async def get_suggestions(self, supabase_client: SupabaseClient) -> List[FilterSuggestion]:
        """Get filter suggestions for this filter type"""
        pass


class PriceRangeFilter(FilterPlugin):
    """Filter products by price range"""
    
    @property
    def filter_type(self) -> str:
        return "price_range"
    
    def apply_filter(self, query, criteria: FilterCriteria):
        params = criteria.parameters
        if "min_price" in params and params["min_price"] is not None:
            query = query.gte("retail_sale_price", params["min_price"])
        if "max_price" in params and params["max_price"] is not None:
            query = query.lte("retail_sale_price", params["max_price"])
        return query
    
    async def get_suggestions(self, supabase_client: SupabaseClient) -> List[FilterSuggestion]:
        # Get dynamic price ranges based on actual data
        price_range = await supabase_client.get_price_range()
        max_price = price_range.get("max_price", 1000)

        # Create dynamic price ranges
        ranges = []
        if max_price > 100:
            ranges.append(FilterSuggestion(type="price_range", label="Under ₹100", value={"max_price": 100}))
        if max_price > 500:
            ranges.extend([
                FilterSuggestion(type="price_range", label="₹100 - ₹500", value={"min_price": 100, "max_price": 500}),
                FilterSuggestion(type="price_range", label="₹500 - ₹1000", value={"min_price": 500, "max_price": 1000}),
            ])
        if max_price > 1000:
            ranges.append(FilterSuggestion(type="price_range", label="Above ₹1000", value={"min_price": 1000}))

        return ranges


class CategoryFilter(FilterPlugin):
    """Filter products by category"""
    
    @property
    def filter_type(self) -> str:
        return "category"
    
    def apply_filter(self, query, criteria: FilterCriteria):
        params = criteria.parameters
        if "category_id" in params:
            query = query.eq("category_id", params["category_id"])
        if "subcategory_id" in params:
            query = query.eq("subcategory_id", params["subcategory_id"])
        return query
    
    async def get_suggestions(self, supabase_client: SupabaseClient) -> List[FilterSuggestion]:
        # Fetch actual categories from database
        categories = await supabase_client.get_product_categories()
        return [
            FilterSuggestion(
                type="category",
                label=cat["name"],
                value={"category_id": cat["id"]}
            ) for cat in categories[:10]  # Limit to top 10 categories
        ]


class StockFilter(FilterPlugin):
    """Filter products by stock availability"""
    
    @property
    def filter_type(self) -> str:
        return "stock"
    
    def apply_filter(self, query, criteria: FilterCriteria):
        params = criteria.parameters
        if params.get("in_stock_only", False):
            query = query.eq("in_stock", True)
        return query
    
    async def get_suggestions(self, supabase_client: SupabaseClient) -> List[FilterSuggestion]:
        return [
            FilterSuggestion(type="stock", label="In Stock Only", value={"in_stock_only": True}),
        ]


class BrandFilter(FilterPlugin):
    """Filter products by brand"""
    
    @property
    def filter_type(self) -> str:
        return "brand"
    
    def apply_filter(self, query, criteria: FilterCriteria):
        params = criteria.parameters
        if "brands" in params and params["brands"]:
            query = query.in_("brand", params["brands"])
        return query
    
    async def get_suggestions(self, supabase_client: SupabaseClient) -> List[FilterSuggestion]:
        # Fetch actual brands from database
        brands = await supabase_client.get_product_brands()
        return [
            FilterSuggestion(
                type="brand",
                label=brand["name"],
                value={"brands": [brand["name"]]}
            ) for brand in brands[:10]  # Limit to top 10 brands
        ]


class RatingFilter(FilterPlugin):
    """Filter products by rating"""
    
    @property
    def filter_type(self) -> str:
        return "rating"
    
    def apply_filter(self, query, criteria: FilterCriteria):
        params = criteria.parameters
        if "min_rating" in params and params["min_rating"] is not None:
            query = query.gte("ratings_avg", params["min_rating"])
        return query
    
    async def get_suggestions(self, supabase_client: SupabaseClient) -> List[FilterSuggestion]:
        return [
            FilterSuggestion(type="rating", label="4+ Stars", value={"min_rating": 4.0}),
            FilterSuggestion(type="rating", label="3+ Stars", value={"min_rating": 3.0}),
        ]


class ProductFilterEngine:
    """Enterprise-grade filter engine for products"""
    
    def __init__(self, supabase_client: SupabaseClient):
        self.supabase_client = supabase_client
        self.plugins: Dict[str, FilterPlugin] = {}
        self._register_default_plugins()
    
    def _register_default_plugins(self):
        """Register default filter plugins"""
        plugins = [
            PriceRangeFilter(),
            CategoryFilter(),
            StockFilter(),
            BrandFilter(),
            RatingFilter(),
        ]
        
        for plugin in plugins:
            self.plugins[plugin.filter_type] = plugin
    
    def register_plugin(self, plugin: FilterPlugin):
        """Register a new filter plugin"""
        self.plugins[plugin.filter_type] = plugin
    
    def _apply_sort(self, query, sort_option: SortOption):
        """Apply sorting to the query"""
        sort_mapping = {
            SortOption.PRICE_LOW_TO_HIGH: ("retail_sale_price", True),
            SortOption.PRICE_HIGH_TO_LOW: ("retail_sale_price", False),
            SortOption.NAME_A_TO_Z: ("name", True),
            SortOption.NAME_Z_TO_A: ("name", False),
            SortOption.NEWEST_FIRST: ("created_at", False),
            SortOption.OLDEST_FIRST: ("created_at", True),
            SortOption.RATING_HIGH_TO_LOW: ("ratings_avg", False),
            SortOption.RATING_LOW_TO_HIGH: ("ratings_avg", True),
        }
        
        if sort_option in sort_mapping:
            column, ascending = sort_mapping[sort_option]
            query = query.order(column, ascending=ascending)
        
        return query
    
    async def apply_filters(
        self,
        filters: List[FilterCriteria],
        sort_option: SortOption = SortOption.NEWEST_FIRST,
        page: int = 1,
        page_size: int = 20,
        search_query: Optional[str] = None
    ) -> ProductFilterResponse:
        """Apply filters and return filtered products"""
        start_time = time.time()
        
        # Start with base query
        query = self.supabase_client.client.from_("products").select("*", count="exact")
        
        # Apply active filter
        query = query.eq("is_active", True)
        
        # Apply search if provided
        if search_query:
            query = query.or_(f"name.ilike.%{search_query}%,description.ilike.%{search_query}%")
        
        # Apply filters using plugins
        for filter_criteria in filters:
            if filter_criteria.type in self.plugins:
                plugin = self.plugins[filter_criteria.type]
                query = plugin.apply_filter(query, filter_criteria)
        
        # Apply sorting
        query = self._apply_sort(query, sort_option)
        
        # Apply pagination
        start = (page - 1) * page_size
        end = start + page_size - 1
        query = query.range(start, end)
        
        # Execute query
        response = await query.execute()
        
        # Calculate performance metrics
        end_time = time.time()
        performance_metrics = {
            "query_time_ms": round((end_time - start_time) * 1000, 2),
            "total_filters": len(filters),
            "timestamp": datetime.utcnow().isoformat()
        }
        
        # Get available filter suggestions
        available_filters = await self._get_available_filters()
        
        return ProductFilterResponse(
            products=response.data or [],
            total_count=response.count or 0,
            page=page,
            page_size=page_size,
            applied_filters=filters,
            available_filters=available_filters,
            sort_option=sort_option,
            performance_metrics=performance_metrics
        )
    
    async def _get_available_filters(self) -> List[FilterSuggestion]:
        """Get available filter suggestions from all plugins"""
        suggestions = []
        for plugin in self.plugins.values():
            plugin_suggestions = await plugin.get_suggestions(self.supabase_client)
            suggestions.extend(plugin_suggestions)
        return suggestions
    
    async def get_filter_suggestions(self, context: Optional[Dict[str, Any]] = None) -> List[FilterSuggestion]:
        """Get smart filter suggestions based on context"""
        return await self._get_available_filters()
