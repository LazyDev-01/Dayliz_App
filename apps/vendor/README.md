# Dayliz Vendor Panel

A modern, responsive vendor management panel built with React, Vite, TypeScript, and Ant Design.

## 🚀 Features

### Phase 1 (Current - Supabase Foundation)
- ✅ **Service Layer Architecture** - Future-proof backend switching capability
- ✅ **Vendor Authentication** - Secure login with Supabase Auth
- ✅ **Mobile-Responsive UI** - Mobile-first design with Ant Design
- ✅ **Real-time Ready** - Infrastructure for real-time order updates
- ✅ **PWA Support** - Progressive Web App capabilities
- 🔄 **Order Management** - Real-time order listing and status updates (In Progress)
- 🔄 **Product Management** - Product listing and inventory updates (In Progress)

### Phase 2 (Planned - FastAPI Migration)
- 🔄 **FastAPI Backend** - Seamless migration to FastAPI
- 🔄 **Enhanced Performance** - Optimized queries and caching
- 🔄 **Advanced Analytics** - Comprehensive reporting dashboard
- 🔄 **Bulk Operations** - Efficient batch processing

## 🛠️ Tech Stack

- **Frontend**: React 18 + TypeScript
- **Build Tool**: Vite
- **UI Framework**: Ant Design 5
- **State Management**: Zustand
- **Data Fetching**: React Query
- **Routing**: React Router v6
- **Backend**: Supabase (Phase 1) → FastAPI (Phase 2)
- **PWA**: Vite PWA Plugin

## 📁 Project Structure

```
src/
├── components/          # Reusable UI components
│   └── layout/         # Layout components
├── pages/              # Page components
├── services/           # Service layer (Supabase/FastAPI)
│   ├── interfaces.ts   # Abstract service interfaces
│   ├── supabase.ts     # Supabase implementation
│   └── index.ts        # Service factory
├── stores/             # Zustand stores
├── types/              # TypeScript type definitions
├── hooks/              # Custom React hooks
└── utils/              # Utility functions
```

## 🚀 Getting Started

### Prerequisites
- Node.js 16+
- npm or yarn

### Installation

1. **Install dependencies**
   ```bash
   npm install
   ```

2. **Environment Setup**
   ```bash
   cp .env.example .env
   ```
   
   Update `.env` with your Supabase credentials:
   ```env
   VITE_SUPABASE_URL=your_supabase_url
   VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

3. **Start Development Server**
   ```bash
   npm run dev
   ```

4. **Build for Production**
   ```bash
   npm run build
   ```

## 🔧 Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run preview` - Preview production build
- `npm run lint` - Run ESLint
- `npm run lint:fix` - Fix ESLint issues
- `npm run type-check` - Run TypeScript type checking
- `npm run test` - Run tests
- `npm run test:ui` - Run tests with UI

## 🏗️ Architecture

### Service Layer Pattern
The vendor panel implements a service layer architecture that allows seamless switching between backends:

```typescript
// Abstract interface
interface VendorDataService {
  getOrders(vendorId: string): Promise<Order[]>
  updateOrderStatus(orderId: string, status: string): Promise<void>
  // ... other methods
}

// Supabase implementation (Phase 1)
class SupabaseVendorService implements VendorDataService {
  // Implementation using Supabase
}

// FastAPI implementation (Phase 2)
class FastAPIVendorService implements VendorDataService {
  // Implementation using FastAPI
}
```

### State Management
- **Zustand** for global state management
- **React Query** for server state and caching
- **Persistent storage** for authentication state

### Real-time Updates
- Supabase real-time subscriptions for live order updates
- WebSocket support for FastAPI migration
- Optimistic updates for better UX

## 📱 Mobile Responsiveness

The vendor panel is designed mobile-first with:
- Collapsible sidebar navigation
- Touch-friendly interface
- Responsive grid layouts
- Mobile-optimized forms

## 🔐 Authentication

- Secure vendor authentication via Supabase Auth
- Session persistence
- Role-based access control
- Automatic token refresh

## 🚀 Deployment

### Development
```bash
npm run dev
```

### Production Build
```bash
npm run build
npm run preview
```

### PWA Features
- Offline support
- Push notifications (planned)
- App-like experience
- Automatic updates

## 🔄 Migration Strategy (Phase 2)

The service layer architecture enables seamless migration:

1. **Parallel Testing** - Run both backends simultaneously
2. **Feature Parity** - Ensure FastAPI matches Supabase functionality
3. **Gradual Migration** - Migrate vendors in batches
4. **Rollback Capability** - Quick revert if issues arise

## 📊 Performance Targets

- **Page Load Time**: <2 seconds
- **Order Processing**: <5 seconds end-to-end
- **Real-time Latency**: <500ms
- **Bundle Size**: <500KB (gzipped)

## 🤝 Contributing

1. Follow the established architecture patterns
2. Use TypeScript for type safety
3. Write tests for new features
4. Follow the mobile-first design approach
5. Maintain service layer abstraction

## 📄 License

Proprietary - Dayliz Team
