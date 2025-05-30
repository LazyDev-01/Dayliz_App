from datetime import datetime, date
from decimal import Decimal
from typing import Any, Dict, List, Optional, Union
from uuid import UUID
import json

class TypeConverters:
    """
    Utility class for handling type conversions between different layers
    of the application (API, database, UI).
    """
    
    @staticmethod
    def to_id_string(id_value: Any) -> str:
        """Convert any ID type to string format"""
        if id_value is None:
            return ""
        if isinstance(id_value, UUID):
            return str(id_value)
        return str(id_value)
    
    @staticmethod
    def to_uuid(id_value: Any) -> Optional[UUID]:
        """Convert string ID to UUID"""
        if id_value is None:
            return None
        if isinstance(id_value, UUID):
            return id_value
        try:
            return UUID(str(id_value))
        except ValueError:
            return None
    
    @staticmethod
    def to_decimal(value: Any) -> Decimal:
        """Convert any value to Decimal with 2 decimal places"""
        if value is None:
            return Decimal('0.00')
        if isinstance(value, Decimal):
            return value.quantize(Decimal('0.01'))
        if isinstance(value, (int, float)):
            return Decimal(str(value)).quantize(Decimal('0.01'))
        if isinstance(value, str):
            try:
                return Decimal(value).quantize(Decimal('0.01'))
            except:
                return Decimal('0.00')
        return Decimal('0.00')
    
    @staticmethod
    def to_float(value: Any) -> float:
        """Convert any value to float with 2 decimal places"""
        if value is None:
            return 0.0
        if isinstance(value, Decimal):
            return float(value)
        if isinstance(value, (int, float)):
            return round(float(value), 2)
        if isinstance(value, str):
            try:
                return round(float(value), 2)
            except:
                return 0.0
        return 0.0
    
    @staticmethod
    def to_datetime(value: Any) -> Optional[datetime]:
        """Convert any value to datetime"""
        if value is None:
            return None
        if isinstance(value, datetime):
            return value
        if isinstance(value, str):
            try:
                return datetime.fromisoformat(value.replace('Z', '+00:00'))
            except:
                try:
                    return datetime.strptime(value, "%Y-%m-%d")
                except:
                    return None
        return None
    
    @staticmethod
    def from_datetime(dt: Optional[datetime]) -> str:
        """Convert datetime to ISO format string"""
        if dt is None:
            return ""
        return dt.isoformat()
    
    @staticmethod
    def to_date(value: Any) -> Optional[date]:
        """Convert any value to date"""
        if value is None:
            return None
        if isinstance(value, date):
            return value
        if isinstance(value, datetime):
            return value.date()
        if isinstance(value, str):
            try:
                return datetime.strptime(value, "%Y-%m-%d").date()
            except:
                try:
                    return datetime.fromisoformat(value.replace('Z', '+00:00')).date()
                except:
                    return None
        return None
    
    @staticmethod
    def to_bool(value: Any) -> bool:
        """Convert any value to boolean"""
        if value is None:
            return False
        if isinstance(value, bool):
            return value
        if isinstance(value, str):
            return value.lower() in ('true', 'yes', '1', 'y')
        if isinstance(value, (int, float)):
            return value != 0
        return False
    
    @staticmethod
    def to_dict(value: Any) -> Dict:
        """Convert any value to dictionary"""
        if value is None:
            return {}
        if isinstance(value, dict):
            return value
        if isinstance(value, str):
            try:
                return json.loads(value)
            except:
                return {}
        return {}
