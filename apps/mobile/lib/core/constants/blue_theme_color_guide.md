# Dayliz App - Modern Blue-Themed Grocery Color Palette Guide

## 🎨 Color Philosophy

The Dayliz app uses a modern blue-themed grocery color palette designed to:
- **Build trust and reliability** with professional blue tones
- **Evoke freshness** with complementary green accents
- **Stimulate appetite** with warm orange highlights
- **Enhance usability** with high contrast and accessibility

## 🌈 Primary Color Palette

### **Primary Colors - Modern Blue Theme**
```dart
AppColors.primary        // #1976D2 - Modern, trustworthy blue (main brand color)
AppColors.primaryLight   // #63A4FF - Light sky blue (hover states, highlights)
AppColors.primaryDark    // #004BA0 - Deep navy blue (pressed states, emphasis)
```

### **Secondary Colors - Fresh Green Theme**
```dart
AppColors.secondary      // #4CAF50 - Fresh green for grocery appeal (CTAs, accent elements)
AppColors.secondaryLight // #81C784 - Light green (hover states)
AppColors.secondaryDark  // #388E3C - Deep green (pressed states)
```

### **Accent Colors - Warm Orange**
```dart
AppColors.accent         // #FF9800 - Warm orange (highlights, badges)
AppColors.accentLight    // #FFB74D - Light orange (backgrounds)
AppColors.accentDark     // #F57C00 - Deep orange (emphasis)
```

## 🏷️ Semantic Colors

### **Standard Semantic Colors**
```dart
AppColors.error          // #E53935 - Bright red for errors
AppColors.success        // #2E7D32 - Deep green for success
AppColors.info           // #1976D2 - Blue for information (matches primary)
AppColors.warning        // #FF8F00 - Orange for warnings
```

### **Grocery-Specific Semantic Colors**
```dart
AppColors.fresh          // #4CAF50 - Fresh produce indicators
AppColors.organic        // #8BC34A - Organic product badges
AppColors.premium        // #673AB7 - Premium product indicators (purple)
AppColors.discount       // #E91E63 - Discount and offer badges
AppColors.sale           // #FF5722 - Sale item indicators
AppColors.newProduct     // #00BCD4 - New arrival badges
```

## 🗂️ Category Colors

Each product category has its own color for visual distinction:

```dart
AppColors.categoryFruits     // #FF6B6B - Red for fruits
AppColors.categoryVegetables // #4ECDC4 - Teal for vegetables
AppColors.categoryDairy      // #FFE66D - Yellow for dairy
AppColors.categoryMeat       // #FF8A80 - Light red for meat
AppColors.categoryBakery     // #FFB74D - Orange for bakery
AppColors.categoryBeverages  // #64B5F6 - Light blue for beverages
AppColors.categorySnacks     // #BA68C8 - Purple for snacks
AppColors.categoryFrozen     // #81D4FA - Light blue for frozen
```

## 📱 UI Element Colors

### **Text Colors**
```dart
AppColors.textPrimary        // #0D47A1 - Dark blue for primary text
AppColors.textSecondary      // #1565C0 - Medium blue for secondary text
AppColors.textTertiary       // #757575 - Standard grey for tertiary text
AppColors.textOnPrimary      // #FFFFFF - White text on primary backgrounds
```

### **Background Colors**
```dart
AppColors.background         // #F8FAFE - Very light blue tint
AppColors.surface           // #FFFFFF - Pure white for cards/surfaces
AppColors.surfaceVariant    // #F3F7FE - Light blue-tinted surface
```

### **UI Elements**
```dart
AppColors.divider           // #E3F2FD - Light blue divider
AppColors.cardShadow        // #1A1976D2 - Blue-tinted shadow
AppColors.shimmerBase       // #F0F6FF - Light blue shimmer base
AppColors.shimmerHighlight  // #FFFFFF - White shimmer highlight
```

## 📊 Order Status Colors

```dart
AppColors.statusPending         // #FF9800 - Orange for pending orders
AppColors.statusConfirmed       // #1976D2 - Blue for confirmed orders (matches primary)
AppColors.statusPreparing       // #FF5722 - Red-orange for preparing
AppColors.statusOutForDelivery  // #9C27B0 - Purple for out for delivery
AppColors.statusDelivered       // #4CAF50 - Green for delivered
AppColors.statusCancelled       // #757575 - Grey for cancelled
```

## 🎨 Gradient Colors

Pre-defined gradients for modern visual appeal:

```dart
AppColors.gradientPrimary    // Blue gradient for primary elements
AppColors.gradientSecondary  // Green gradient for secondary elements
AppColors.gradientBackground // Subtle blue background gradient
AppColors.gradientCard       // Card gradient for depth
```

## 🎯 Usage Guidelines

### **Primary Blue** - Use for:
- Main action buttons (Add to Cart, Buy Now)
- Navigation active states
- Information indicators
- Trust-building elements
- Confirmed order status

### **Secondary Green** - Use for:
- Fresh/organic product badges
- Success indicators
- Delivered status
- Eco-friendly elements

### **Accent Orange** - Use for:
- Discount badges
- Warning indicators
- Call-to-action elements
- Appetite-stimulating accents

### **Category Colors** - Use for:
- Product category identification
- Filter chips
- Category navigation
- Visual organization

## ♿ Accessibility

All colors meet WCAG 2.1 AA standards:
- **Contrast ratio**: Minimum 4.5:1 for normal text
- **Large text**: Minimum 3:1 contrast ratio
- **Focus indicators**: High contrast blue (#1976D2)
- **High contrast mode**: Pure black (#000000) available

## 🔄 Migration from Old Colors

### **Old → New Mapping**
```dart
// Old basic blue → New modern blue
Color(0xFF0066CC) → AppColors.primary (#1976D2)

// Old orange → New warm orange
Color(0xFFFF9500) → AppColors.accent (#FF9800)

// Old green → New fresh green (secondary)
Color(0xFF388E3C) → AppColors.secondary (#4CAF50)

// Old background → New blue-tinted background
Color(0xFFF8F9FA) → AppColors.background (#F8FAFE)
```

## 🛠️ Implementation Examples

### **Button with Primary Blue**
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.textOnPrimary,
  ),
  child: Text('Add to Cart'),
)
```

### **Product Card with Category Color**
```dart
Container(
  decoration: BoxDecoration(
    color: AppColors.surface,
    border: Border.left(
      color: AppColors.categoryFruits, // For fruits category
      width: 4,
    ),
  ),
)
```

### **Order Status Badge**
```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  decoration: BoxDecoration(
    color: AppColors.statusConfirmed,
    borderRadius: BorderRadius.circular(16),
  ),
  child: Text(
    'Confirmed',
    style: TextStyle(
      color: AppColors.textOnPrimary,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
  ),
)
```

### **Fresh Product Badge**
```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  decoration: BoxDecoration(
    color: AppColors.fresh,
    borderRadius: BorderRadius.circular(4),
  ),
  child: Text(
    'FRESH',
    style: TextStyle(
      color: AppColors.textOnPrimary,
      fontWeight: FontWeight.bold,
      fontSize: 10,
    ),
  ),
)
```

## 🎨 Color Psychology

### **Blue Primary Theme Benefits:**
- **Trust & Reliability**: Blue is associated with trustworthiness and professionalism
- **Calm & Stable**: Creates a sense of security for financial transactions
- **Universal Appeal**: Blue is widely accepted across cultures and demographics
- **Tech-Forward**: Aligns with modern app design trends

### **Green Secondary Accents:**
- **Freshness**: Perfect for grocery and food-related content
- **Health & Wellness**: Associated with organic and healthy products
- **Growth & Prosperity**: Positive associations with success

### **Orange Highlights:**
- **Energy & Enthusiasm**: Creates excitement for deals and offers
- **Appetite Stimulation**: Warm colors encourage food purchases
- **Call-to-Action**: Draws attention to important buttons and badges

This blue-themed grocery color palette creates a trustworthy, professional, and fresh visual experience that builds user confidence while maintaining the appetizing qualities essential for a grocery delivery app.