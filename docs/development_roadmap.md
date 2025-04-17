# Dayliz App Development Roadmap

This document outlines the development roadmap for the Dayliz App, a q-commerce grocery delivery app for the Indian market. The development follows a "Serial Stacked Sprint" approach, building the app layer-by-layer in sequential phases.

## Development Approach

The "Serial Stacked Sprint" approach involves:
1. Focusing on one phase at a time
2. Completing all critical components of a phase before moving to the next
3. Setting milestone-based checkpoints for integration
4. Regular testing and validation at the end of each phase

## Backend Architecture Direction

> **IMPORTANT**: The FastAPI backend under /backend is feature-complete but not connected yet.
> We are keeping Supabase as the active backend for Phases 1-5 to build and launch fast.
> The service layer abstraction in Flutter allows for a future switch with minimal UI rewrites.
> FastAPI migration is planned for Phase 6 (post-launch) when we need custom logic, RBAC, or scale limits.
> In the meantime, any core DB model changes should be synced with FastAPI models to avoid drift.

## Phase 1: Foundation Setup (2-3 weeks)

### Authentication System
- [x] Setup Supabase project and configure auth providers
- [x] Implement email/phone authentication
- [x] Create secure token storage with refresh mechanism
- [x] Build login, registration, and password reset screens
- [x] Add persistent login state

### Design System
- [x] Define typography scale and color palette
- [x] Create spacing and layout grid system
- [x] Implement theme provider with light/dark mode
- [x] Define elevation and shadow system
- [x] Create design tokens documentation

### Custom Components
- [x] Create button variants (primary, secondary, ghost, danger, tertiary)
- [x] Build input fields with validation states
- [x] Implement card and container components
- [x] Create loading indicators and shimmer placeholders
- [x] Design navigation components (tabs, bottom bar)

### Navigation
- [x] Setup GoRouter with path-based routing
- [x] Implement authentication route guards
- [x] Create custom page transitions
- [x] Add deep linking support
- [x] Handle 404/error routes

### Backend Foundation
- [x] Create FastAPI project structure *(feature-complete but not integrated)*
- [x] Setup database with SQLAlchemy ORM *(feature-complete but not integrated)*
- [x] Implement JWT authentication *(feature-complete but not integrated)*
- [x] Define core models (User, Product, Order) *(feature-complete in both FastAPI and Supabase)*
- [x] Create migration system *(feature-complete but not integrated)*
- [x] Implement basic CRUD operations *(implemented in both FastAPI and Supabase)*

## Phase 2: Product Browsing + UI Polish (2-3 weeks)

### Product Catalog
- [x] Create product listing endpoint with pagination
- [x] Implement category and filtering APIs
- [x] Add search functionality with relevance scoring
- [x] Build sorting and filtering options
- [x] Implement product detail endpoints

### UI Implementation
- [x] Create home screen with featured products
- [x] Build category browser with horizontal scrolling
- [x] Implement product grid with staggered loading
- [x] Design product detail screen with images and info
- [x] Add ratings and reviews section

### Cart Functionality
- [x] Implement cart provider with Riverpod
- [x] Create add-to-cart animation
- [x] Build optimistic UI updates for cart operations
- [x] Implement quantity adjustment with haptic feedback
- [x] Add cart persistence with local storage

### Animations & Polish
- [x] Add hero transitions for product images
- [x] Implement scroll animations
- [x] Create micro-interactions for buttons and inputs
- [x] Add pull-to-refresh with custom animation
- [x] Implement skeleton loading for data-dependent screens

## Phase 3: Checkout & Payment (2-3 weeks)

### Address Management
- [x] Create address database models and API
- [ ] Implement Google Maps integration
- [x] Build address form with validation
- [x] Add address saving and selection UI
- [x] Implement default address functionality

### Cart & Order Flow
- [x] Create cart summary screen
- [x] Build order creation API
- [ ] Implement inventory verification
- [x] Add order confirmation screen
- [ ] Create order notification system

### Payment Integration
- [ ] Setup Razorpay test environment
- [ ] Implement payment creation endpoint
- [ ] Build payment UI with Razorpay SDK
- [ ] Add webhook handling for payment events
- [ ] Implement order status updates

### Order Management
- [ ] Create order detail screen
- [ ] Implement order cancellation
- [ ] Build order summary API
- [ ] Add receipt generation
- [ ] Implement payment retries

## Phase 4: User Profile + Order History (2 weeks)

### User Profile
- [x] Create profile screen with user details
- [ ] Implement profile editing functionality
- [ ] Add avatar upload with image cropping
- [x] Build settings screen
- [ ] Implement account deletion

### Order History
- [x] Create order history endpoint
- [ ] Build order history UI
- [ ] Implement order detail view
- [ ] Add reorder functionality
- [ ] Create order tracking screen

### Delivery Tracking
- [ ] Implement order status update API
- [ ] Create real-time status updates
- [ ] Build delivery tracking map
- [ ] Add estimated delivery time
- [ ] Implement delivery feedback

### Notifications
- [ ] Setup Firebase Cloud Messaging
- [ ] Implement notification handlers
- [ ] Create local notifications for offline events
- [ ] Add notification settings
- [ ] Build notification inbox UI

## Phase 5: Polish & Launch Prep (2 weeks)

### UI Finalization
- [ ] Complete dark mode implementation
- [ ] Add final icons and illustrations
- [ ] Implement splash screen and app icon
- [ ] Optimize animations for performance
- [ ] Ensure consistent UI across all flows

### Error Handling
- [x] Implement comprehensive error states
- [ ] Add offline mode handling
- [ ] Create retry mechanisms
- [ ] Implement crash reporting
- [x] Add user-friendly error messages

### Performance Optimization
- [ ] Run Flutter performance profiling
- [x] Optimize image loading and caching
- [ ] Reduce unnecessary rebuilds
- [ ] Implement background fetch for critical data
- [ ] Optimize app size

### Launch Preparation
- [ ] Conduct user testing
- [ ] Prepare Play Store listing
- [ ] Complete privacy policy and terms
- [ ] Setup analytics
- [ ] Create app promotional materials

## Phase 6: Backend Migration (3-4 weeks)

> **NOTE**: This phase occurs post-launch, allowing us to focus on feature delivery and user experience first.

### API Transition
- [ ] Integrate FastAPI backend with Flutter app
- [ ] Implement hybrid gateway approach for selective routing
- [ ] Create comprehensive API tests
- [ ] Ensure backward compatibility with existing features

### Advanced Features
- [ ] Migrate critical business logic from Supabase to FastAPI
- [ ] Add advanced RBAC (Role-Based Access Control)
- [ ] Implement custom analytics and reporting
- [ ] Build advanced search and recommendation algorithms

### Infrastructure
- [ ] Set up production deployment pipeline
- [ ] Implement CI/CD for backend
- [ ] Set up monitoring and logging infrastructure
- [ ] Create database migration strategy
- [ ] Configure auto-scaling

### Performance
- [ ] Conduct performance testing and optimization
- [ ] Implement caching mechanisms
- [ ] Optimize database queries
- [ ] Create benchmarking tools

## Project Timeline

| Phase | Duration | Target Completion |
|-------|----------|-------------------|
| Phase 1: Foundation | 2-3 weeks | Week 3 |
| Phase 2: Product Browsing | 2-3 weeks | Week 6 |
| Phase 3: Checkout & Payment | 2-3 weeks | Week 9 |
| Phase 4: User Profile & Orders | 2 weeks | Week 11 |
| Phase 5: Polish & Launch | 2 weeks | Week 13 |
| **APP LAUNCH** | | **Week 13** |
| Phase 6: Backend Migration | 3-4 weeks | Week 17 |

Total estimated time to launch: 10-13 weeks 
