# 🛒 Dayliz - Q-Commerce Grocery Delivery Platform

**The next-generation grocery delivery platform for Northeast India, expanding across all of India.**

[![Flutter](https://img.shields.io/badge/Flutter-3.32.0-blue.svg)](https://flutter.dev/)
[![FastAPI](https://img.shields.io/badge/FastAPI-Latest-green.svg)](https://fastapi.tiangolo.com/)
[![Supabase](https://img.shields.io/badge/Supabase-Latest-orange.svg)](https://supabase.com/)

## 🏗️ Monorepo Architecture

This is a **professional monorepo** containing all Dayliz applications and services:

```
Project_Dayliz/
├── apps/                    # All applications
│   ├── mobile/             # Flutter mobile app
│   ├── web-dashboard/      # Admin web dashboard (planned)
│   ├── vendor-portal/      # Vendor management portal (planned)
│   └── delivery-app/       # Delivery agent app (planned)
├── services/               # Backend services
│   └── api/               # FastAPI backend service
├── packages/              # Shared packages
│   ├── shared-types/      # Common data types
│   ├── ui-components/     # Reusable UI components
│   ├── business-logic/    # Shared business logic
│   └── utils/            # Utility functions
├── infrastructure/        # Infrastructure & DevOps
│   └── database/         # Database configurations
├── tools/                # Development tools
│   ├── scripts/          # Build and deployment scripts
│   └── configs/          # Configuration files
└── docs/                 # Documentation
```

## 🚀 Quick Start

### For Mobile Development
```bash
cd apps/mobile
flutter pub get
flutter run
```

### For Backend Development
```bash
cd services/api
pip install -r requirements.txt
uvicorn app.main:app --reload
```

## 🎯 Applications

### 📱 Mobile App (`apps/mobile/`)
- **Tech Stack**: Flutter 3.32.0, Dart
- **Features**: User authentication, product browsing, cart, orders
- **Target**: iOS & Android customers

### 🌐 Web Dashboard (`apps/web-dashboard/`) *[Planned]*
- **Tech Stack**: React/Next.js
- **Features**: Admin panel, analytics, user management
- **Target**: Business administrators

### 🏪 Vendor Portal (`apps/vendor-portal/`) *[Planned]*
- **Tech Stack**: React/Vue.js
- **Features**: Inventory management, order processing
- **Target**: Store owners and vendors

### 🚚 Delivery App (`apps/delivery-app/`) *[Planned]*
- **Tech Stack**: Flutter/React Native
- **Features**: Route optimization, delivery tracking
- **Target**: Delivery agents

## 🛠️ Services

### 🔧 API Service (`services/api/`)
- **Tech Stack**: FastAPI, Python
- **Features**: RESTful API, authentication, business logic
- **Database**: PostgreSQL via Supabase

## 📦 Shared Packages

### 🔗 Shared Types (`packages/shared-types/`)
Common data models and type definitions used across all applications.

### 🎨 UI Components (`packages/ui-components/`)
Reusable UI components for consistent design across platforms.

### 💼 Business Logic (`packages/business-logic/`)
Core business rules and logic shared between frontend and backend.

### 🔧 Utils (`packages/utils/`)
Common utility functions and helpers.

## 🏗️ Infrastructure

### 🗄️ Database (`infrastructure/database/`)
- **Primary**: Supabase (PostgreSQL)
- **Features**: Real-time subscriptions, authentication, storage
- **Migrations**: Automated database schema management

## 🛠️ Development Tools

### 📜 Scripts (`tools/scripts/`)
- Build automation
- Deployment scripts
- Testing utilities
- Code generation

### ⚙️ Configs (`tools/configs/`)
- Environment configurations
- CI/CD pipeline configs
- Code quality tools

## 📚 Documentation

- **[Architecture Guide](docs/architecture/)** - System design and patterns
- **[API Documentation](docs/api/)** - Backend API reference
- **[Setup Guide](docs/onboarding/)** - Development environment setup
- **[Migration Guide](docs/migration/)** - Legacy to clean architecture migration

## 🎯 Business Goals

- **Phase 1**: Dominate Northeast India grocery delivery market
- **Phase 2**: Expand to major Indian metropolitan cities
- **Phase 3**: Pan-India coverage with advanced features
- **Vision**: Become India's leading q-commerce platform

## 🤝 Team Collaboration

### 👥 Team Structure
- **Mobile Developers**: Work in `apps/mobile/`
- **Web Developers**: Work in `apps/web-dashboard/`, `apps/vendor-portal/`
- **Backend Developers**: Work in `services/api/`
- **DevOps Engineers**: Work in `infrastructure/`
- **Product Managers**: Access all documentation in `docs/`

### 🔄 Development Workflow
1. **Feature Development**: Create feature branches
2. **Code Review**: All changes require PR approval
3. **Testing**: Automated testing for all components
4. **Deployment**: Automated CI/CD pipeline

## 🚀 Getting Started for New Team Members

1. **Clone the repository**:
   ```bash
   git clone https://github.com/LazyDev-01/Dayliz_App.git
   cd Project_Dayliz
   ```

2. **Choose your focus area**:
   - **Mobile**: `cd apps/mobile && flutter pub get`
   - **Backend**: `cd services/api && pip install -r requirements.txt`
   - **Web**: `cd apps/web-dashboard && npm install`

3. **Read the documentation**:
   - [Onboarding Guide](docs/onboarding/)
   - [Architecture Overview](docs/architecture/)

## 📈 Project Status

- ✅ **Mobile App**: Production-ready with clean architecture
- ✅ **Backend API**: FastAPI service with Supabase integration
- ✅ **Database**: Supabase PostgreSQL with optimized schema
- 🔄 **Web Dashboard**: In planning phase
- 🔄 **Vendor Portal**: In planning phase
- 🔄 **Delivery App**: In planning phase

## 🏆 Success Metrics

- **Technical**: Clean architecture, 90%+ test coverage, <2s load times
- **Business**: Market leadership in Northeast India, 100k+ active users
- **Team**: Efficient collaboration, fast feature delivery, high code quality

## 📄 License

This project is proprietary software owned by Dayliz. All rights reserved.

---

**Built with ❤️ for the future of grocery delivery in India** 🇮🇳
