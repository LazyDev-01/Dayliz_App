Implement a full-featured Product Listing Screen that activates after the user selects a Main Category Card (e.g., Vegetables & Fruits) from the Home or Category screen. This screen should deliver a seamless, responsive browsing experience and allow dynamic filtering by sub-categories, sorting, and product attributes.


Layout Structure :-
1. Sticky Top App Bar

 Displays: Main category title (e.g., Vegetables & Fruits) and total product count.
 Include a search icon that enables searching within results.

2. Sub-category Horizontal Scroll

 Horizontally scrollable pill-style buttons (like: All, Fresh Fruits, Exotic Veggies, etc.)
 Each sub-category is part of the current main category only.
 Show icons (optional) + label.
 “All” resets to show all products under main category.
  Maintain sticky position under the top bar for quick access while scrolling.

3. Sticky Filter / Sort / Brand Section

 Stays pinned below sub-categories while scrolling

 Includes:

    🔽 Filter Button → Opens a modal or bottom sheet with advanced options
    🧠 Sort Dropdown → (e.g., Price Low→High, Popularity, Newest)
    🏷️ Brand Shortcut → Allows brand selection without deep diving

🛍️ Product Grid Section
 Responsive 2-column grid layout
 Option to toggle to list view if needed

 Each product card (in grid view) should now include:
    📸 Product Image (takes top 60% of the card height)
    🏷️ Product Name (1-2 lines max)
    💰 Price & Discount (show original + discounted if applicable)
    ⭐ Rating (small icon + number)
    🔢 Quantity Control Button:
        Default: Shows + Add button
        On click: Transforms into a stepper like [- 1 +]

        Should support:
                Minimum: 1
                Max: Stock limit or preset limit (optional)
                Animation between + Add and [- qty +]

    Position: Stick to the bottom-right of the card for visibility and thumb-reach
Optional: Light shadow behind card for clickable feel

✨ UX Tips for Quantity Stepper
    Show a toast/snackbar: “Added to cart” on first add
    Animate count changes smoothly
    Persist quantities even when scrolling
    Prevent accidental double clicks with debounce

🔍 Filtering Options (Modal or Bottom Sheet)
    Multi-select filters:
    ✅ In-stock only toggle
    🏷️ Brand selection
    💰 Price range slider
    ⭐ Rating filter
    🔖 Discount/Offers toggle
    🧩 Sub-category refinement (nested if needed)
Reset All & Apply buttons

⚙️ Behavior & Logic
    Accepts mainCategoryId and optional subCategoryId as input
    Auto-fetch products via API or service based on:
    Active main category
    Selected sub-category
    Active filters and sort values

Implement:
    Lazy loading / infinite scroll
    Pull-to-refresh to reload
    Retain state on back navigation
    Skeleton loaders for better perceived speed
    “No results” screen with suggestions (e.g., try another filter)

🎨 UX Enhancements
    Smooth animation when filters/sorts are applied
    Edge fade effect on horizontal sub-category list
    Card tap → navigate to Product Detail screen
    Optional: Show total filtered items dynamically
    Floating back-to-top button (after scroll threshold)

🧩 Component Breakdown (Suggested Reusable Widgets)
    SubCategorySelector – pill-style horizontal list
    FilterSortBar – sticky with modular actions
    ProductCard – supports both grid and list view
    FilterSheetModal – bottom sheet with filters
    ProductGrid – with lazy scroll & responsive grid
    EmptyStateComponent – for no results / error

🎯 Acceptance Criteria
    [ ] Functional sub-category horizontal filter (under main category)
    [ ] Filter & sort actions persist until cleared
    [ ] Product list updates in real-time on filter/sort
    [ ] Lazy loading & skeleton loaders
    [ ] Clean back-navigation state retention
    [ ] Fully responsive & optimized across device sizes
    [ ] Animate transitions for add & quantity change
    [ ] Quantity persists per session (optional)
    [ ] No duplicate entries in cart — only qty increments

