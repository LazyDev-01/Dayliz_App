# Dayliz App - Updated User Guidelines 2025

**Last Updated**: June 2025  
**Version**: 3.0  
**Status**: Active Development - Production Readiness Phase

---

## 📋 Project Overview

### Current Project Status
- **Main App**: Production-ready core features with clean architecture implementation
- **Agent App**: MVP foundation complete with demo data integration
- **Admin Panel**: Next.js dashboard with Supabase integration
- **Backend**: FastAPI + Supabase dual architecture (Supabase primary, FastAPI feature-ready)
- **Production Readiness**: 75% complete - Security & compliance implementation in progress

### Technology Stack (Confirmed)
- **Frontend**: Flutter 3.29.2+ with clean architecture
- **Backend**: Supabase (primary) + FastAPI (feature-ready)
- **Database**: Supabase PostgreSQL with RLS policies
- **State Management**: Riverpod
- **Authentication**: Supabase Auth
- **CI/CD**: GitHub Actions with 85% pipeline completion
- **Branch Strategy**: `production-readiness` branch (primary development)

---

## 🏗️ Architecture & Development Standards

### Database Architecture
- Use 'agents' instead of 'drivers' for delivery personnel
- Include RLS policies when making database schema changes
- Use dayliz-dev Supabase project for development work
- Agent authentication uses email/phone, not Agent ID
- Agent registration goes to pending_agents table for team review

### Application Architecture
- **Monorepo Structure**: apps/mobile, apps/agent, apps/admin, services/api
- **Clean Architecture**: Strictly enforced - no legacy code modifications
- **Migration Strategy**: Remove legacy screens one by one during clean architecture migration
- **Cart System**: Local storage only (database sync disabled for early launch)
- **Payment**: Cash on Delivery implemented, Razorpay feature-ready
- **Authentication Flow**: Existing users skip login/signup, go directly to home

### Code Quality Standards
- **Test Coverage**: Target 80%+ with comprehensive testing framework
- **Security**: Zero exposed credentials, proper secrets management
- **Performance**: Ultra-high FPS optimization, skeleton loading preferred
- **Documentation**: Markdown implementation plans before code changes

---

## 🌍 Business Model & Localization

### Geographic Focus
- **Target Market**: India only (affects compliance requirements)
- **Compliance**: DPDP Act 2023 implementation critical (80% complete)
- **Currency**: INR only
- **Delivery Hierarchy**: Region → Zone → Area with geofencing

### Business Rules
- **Delivery Fees**: ₹25 (<₹200), ₹20 (<₹500), Free (≥₹499), ₹29 (rain)
- **Weather Impact**: Smart delivery with weather notifications
- **Zone Detection**: Hidden from users (they see products, not zones)
- **Vendor Model**: Zone-based vendor assignment per category

---

## 🎨 User Experience Standards

### UI/UX Preferences
- **Theme**: Blue theme with light grey backgrounds
- **Loading**: Skeleton loading over circular indicators
- **Animations**: Lottie animations from LottieFiles (Empty_cart, Network_error, success_checkmark)
- **Interactions**: Haptic feedback, bounce effects, smooth animations
- **Navigation**: Clean animated touch feedback, no Material Design splash effects

### Specific UI Elements
- **Location Display**: 'Delivery in [location address]' in app bar title
- **Cart Button**: Floating with animations
- **Splash Screen**: White background, full Lottie animation, 1.5-2s minimum, fade-out
- **Coupons**: Light grey input fields, 'Enter Coupon Code' placeholder
- **Bill Details**: Dotted line separators, 'To Pay' instead of 'Total Amount'

### Screen Behavior
- **Home Screen**: Load once, cache on subsequent navigations
- **Other Screens**: Load once and cache
- **Logout**: Navigate to premium auth landing screen (not login screen)
- **Profile**: Enhanced section containers for better visual hierarchy

---

## 🔧 Development Workflow

### Work Preferences
- **Approach**: Divide-and-conquer for complex implementations
- **Planning**: Detailed markdown implementation plans before coding
- **Code Changes**: AI makes direct codebase changes (not instructions)
- **Balance**: Frontend and backend implementation work
- **Cleanup**: Regular removal of unused/complex code for maintainability

### Package Management
- **Dependencies**: Always use package managers (npm, flutter pub, pip)
- **Never**: Manually edit package.json, pubspec.yaml, requirements.txt
- **Exception**: Only for complex configuration changes

### Testing & Quality
- **Testing Strategy**: Write/update tests after code changes
- **Code Standards**: Clean, simple code with regular cleanup
- **Performance**: Optimize existing features vs creating new implementations
- **Documentation**: Implementation strategies in docs/ directory

---

## 🚀 Current Development Focus

### Production Readiness (Priority 1)
- **Security**: Complete secrets management and vulnerability fixes
- **Compliance**: Finalize DPDP Act 2023 implementation
- **CI/CD**: Complete remaining 15% of pipeline
- **Testing**: Achieve 80%+ test coverage
- **Infrastructure**: Monitoring and alerting systems

### Feature Development (Priority 2)
- **Agent App**: Real data integration (demo data → live functionality)
- **Payment Integration**: COD optimization, Razorpay preparation
- **Location Services**: Google Maps integration completion
- **Order Management**: Real-time tracking and status updates

### Technical Debt (Priority 3)
- **Legacy Cleanup**: Continue removing legacy screens
- **Performance**: Ultra-high FPS optimizations
- **Documentation**: Complete API and architecture documentation
- **Monitoring**: Production monitoring and alerting setup

---

## 🔒 Security & Compliance

### Critical Security Requirements
- **Zero Tolerance**: No exposed credentials in repository
- **Secrets Management**: Proper environment variable handling
- **Debug Code**: Remove all debug prints from production
- **Test Files**: No test files in production lib/ directory
- **API Security**: Proper authentication and authorization

### Compliance Requirements
- **DPDP Act 2023**: Data protection and privacy (80% complete)
- **PCI-DSS**: Payment security standards
- **RBI Guidelines**: Digital payment security compliance
- **Privacy Policy**: Implemented and legally reviewed
- **Terms of Service**: Implemented and legally reviewed

---

## 📞 Communication & Collaboration

### Professional Standards
- **Professionalism**: Treat AI as core project developer
- **Standards**: High-quality code and documentation
- **Decision Making**: Decisive action over extensive planning when stuck
- **Feedback**: Address user feedback by updating task status appropriately

### Documentation Standards
- **Format**: Markdown with consistent structure
- **Location**: docs/ directory for all implementation strategies
- **Updates**: Keep migration progress documented
- **Security**: Never include actual API keys or credentials in docs

---

## 🎯 Success Metrics

### Launch Readiness Targets
- **Security Score**: 8.5/10 (current: 3/10)
- **Compliance Score**: 9/10 (current: 1/10)
- **Technical Readiness**: 9/10 (current: 6/10)
- **Code Quality**: 8.5/10 (current: 7/10)

### Performance Targets
- **Test Coverage**: 80%+
- **API Response Time**: <2s average
- **App Launch Time**: <3s
- **Error Rate**: <1%
- **Uptime**: 99.9%

---

**Note**: These guidelines supersede all previous versions and reflect the current state of the Dayliz App project as of June 2025. Regular updates will be made as the project evolves toward production launch.
