# Dayliz App Design System

This document outlines the design system for the Dayliz App, including typography, colors, spacing, and component guidelines.

## Colors

### Primary Colors
- **Primary**: `#4CAF50` - Used for primary buttons, active states, and key UI elements
- **Primary Dark**: `#388E3C` - Used for hover/pressed states of primary elements
- **Primary Light**: `#C8E6C9` - Used for backgrounds, indicators, and subtle UI elements

### Accent Colors
- **Accent**: `#FFC107` - Used for highlighting important elements, CTAs
- **Accent Secondary**: `#FF9800` - Used as a secondary accent for variety

### Text Colors
- **Text Primary**: `#212121` - Used for headlines and primary content
- **Text Secondary**: `#757575` - Used for secondary text and less important content

### Status Colors
- **Success**: `#4CAF50` - Used for success states and confirmations
- **Info**: `#2196F3` - Used for informational messages
- **Warning**: `#FFC107` - Used for warnings and cautionary messages
- **Error**: `#F44336` - Used for error states and destructive actions

## Typography

We use the Poppins font family throughout the application with the following text styles:

### Headlines
- **Display Large**: 28px, Bold (700) - Used for main headlines
- **Display Medium**: 24px, Bold (700) - Used for section titles
- **Display Small**: 22px, Bold (700) - Used for important headings

### Titles
- **Headline Medium**: 20px, SemiBold (600) - Used for card titles
- **Headline Small**: 18px, SemiBold (600) - Used for section headers
- **Title Large**: 16px, SemiBold (600) - Used for item titles

### Body Text
- **Body Large**: 15px, Regular (400) - Used for primary content
- **Body Medium**: 14px, Regular (400) - Used for general content
- **Body Small**: 12px, Regular (400) - Used for secondary information

### Labels
- **Label Large**: 14px, Medium (500) - Used for button text
- **Label Medium**: 12px, Medium (500) - Used for tags and badges
- **Label Small**: 10px, Medium (500) - Used for small labels and captions

## Spacing

We use a consistent spacing scale throughout the application:

- **xs**: 4dp - Used for minimal spacing between related elements
- **sm**: 8dp - Used for related elements
- **md**: 16dp - Used for general spacing between elements
- **lg**: 24dp - Used for group separation
- **xl**: 32dp - Used for section separation
- **xxl**: 48dp - Used for major section separation

## Border Radius

- **Base**: 8dp - Default border radius for most elements
- **Button**: 8dp - Used for buttons
- **Card**: 12dp - Used for cards and surfaces
- **Input**: 8dp - Used for input fields and form elements

## Elevation

We use consistent elevation levels for layering:

- **Level 0**: 0dp - Background elements
- **Level 1**: 2dp - Cards, surfaces
- **Level 2**: 4dp - Raised components (buttons, FABs)
- **Level 3**: 8dp - Menus, dialogs
- **Level 4**: 16dp - Modal sheets

## Component Guidelines

### Buttons

**Primary Button**
- Background: Primary Color
- Text: White
- Padding: 16dp horizontal, 12dp vertical
- Border Radius: 8dp

**Secondary Button**
- Border: Primary Color (1.5dp)
- Text: Primary Color
- Padding: 16dp horizontal, 12dp vertical
- Border Radius: 8dp

**Text Button**
- Text: Primary Color
- No background or border

### Input Fields

- Background: Light Grey (#F5F5F5)
- Border: None (unfocused), Primary Color (focused)
- Padding: 16dp all sides
- Border Radius: 8dp

### Cards

- Background: White
- Elevation: 2dp
- Border Radius: 12dp
- Padding: 16dp

## Using the Design System in Code

### Accessing Theme Extensions

```dart
// Get the theme extension
final theme = Theme.of(context).extension<DaylizThemeExtension>()!;

// Use spacing constants
SizedBox(height: theme.spacing['md']);

// Use border radius
Container(
  decoration: BoxDecoration(
    borderRadius: theme.cardBorderRadius,
  ),
);

// Use colors
Container(
  color: theme.success,
);
```

### Typography Examples

```dart
Text(
  'Headline',
  style: Theme.of(context).textTheme.displayLarge,
);

Text(
  'Body text',
  style: Theme.of(context).textTheme.bodyMedium,
);
```

### Button Examples

```dart
ElevatedButton(
  onPressed: () {},
  child: Text('Primary Button'),
);

OutlinedButton(
  onPressed: () {},
  child: Text('Secondary Button'),
);

TextButton(
  onPressed: () {},
  child: Text('Text Button'),
);
``` 