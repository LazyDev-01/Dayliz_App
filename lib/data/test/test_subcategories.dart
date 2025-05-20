/// Sample subcategory data for testing the category filter sidebar
class TestSubcategories {
  /// Dairy, Bread & Eggs subcategories
  static const List<String> dairyBreadEggs = [
    'Milk',
    'Bread',
    'Eggs',
    'Yoghurt',
    'Curd',
    'Cheese',
    'Butter',
    'Paneer',
    'Cream',
  ];
  
  /// Fruits & Vegetables subcategories
  static const List<String> fruitsVegetables = [
    'Fresh Fruits',
    'Fresh Vegetables',
    'Herbs & Seasonings',
    'Organic Fruits',
    'Organic Vegetables',
    'Exotic Fruits',
    'Exotic Vegetables',
    'Sprouts',
    'Flower Bouquets',
  ];
  
  /// Snacks & Beverages subcategories
  static const List<String> snacksBeverages = [
    'Chips & Crisps',
    'Soft Drinks',
    'Juices',
    'Tea & Coffee',
    'Energy Drinks',
    'Biscuits & Cookies',
    'Namkeen & Savory',
    'Chocolates',
    'Sweets',
  ];
  
  /// Cleaning & Household subcategories
  static const List<String> cleaningHousehold = [
    'Detergents',
    'Floor Cleaners',
    'Toilet Cleaners',
    'Dishwashing',
    'Fresheners',
    'Cleaning Tools',
    'Tissues & Disposables',
    'Repellents',
    'Pooja Needs',
  ];
  
  /// Beauty & Personal Care subcategories
  static const List<String> beautyPersonalCare = [
    'Bath & Body',
    'Hair Care',
    'Skin Care',
    'Oral Care',
    'Deodorants',
    'Face Care',
    'Feminine Hygiene',
    'Men\'s Grooming',
    'Makeup',
  ];
  
  /// Get subcategories by main category name
  static List<String> getSubcategoriesByCategory(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'dairy, bread & eggs':
      case 'dairy':
      case 'dairy and bread':
        return dairyBreadEggs;
      case 'fruits & vegetables':
      case 'fruits and vegetables':
        return fruitsVegetables;
      case 'snacks & beverages':
      case 'snacks and beverages':
        return snacksBeverages;
      case 'cleaning & household':
      case 'cleaning and household':
        return cleaningHousehold;
      case 'beauty & personal care':
      case 'beauty and personal care':
        return beautyPersonalCare;
      default:
        return [];
    }
  }
}
