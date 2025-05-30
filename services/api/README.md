# Dayliz App Backend

This directory contains the FastAPI backend for the Dayliz App, which serves as an API layer between the Flutter app and Supabase.

## Current Status

- **Feature-complete but not currently connected** to the Flutter app
- The Flutter app is directly using Supabase for Phases 1-5 development
- Planned integration in Phase 6 (post-launch) (see [Development Roadmap](../Dayliz_App/docs/development_roadmap.md))

## Architecture

The backend follows a modern FastAPI architecture with SQLAlchemy ORM:

```
backend/
├── app/                 - Main application package
│   ├── api/             - API endpoints
│   │   └── v1/          - Version 1 API endpoints
│   ├── core/            - Core settings and utilities
│   ├── db/              - Database configuration
│   ├── models/          - SQLAlchemy models
│   ├── schemas/         - Pydantic schemas for validation
│   ├── services/        - Service layer
│   └── main.py          - FastAPI application entry point
├── .env                 - Environment variables
└── requirements.txt     - Python dependencies
```

## Features

- ✅ Complete FastAPI project structure
- ✅ SQLAlchemy ORM integration
- ✅ JWT authentication
- ✅ Core models (User, Product, Order)
- ✅ API endpoints for all core entities
- ✅ Supabase client integration (hybrid approach)

## Integration Plan

The backend is designed to work alongside Supabase in a hybrid approach:

1. **Phases 1-5**: Flutter app connects directly to Supabase for initial development and app launch
2. **Phase 6 (post-launch)**: Migrate to FastAPI backend once core app functionality is stable
3. **Future**: Hybrid gateway approach for selective routing and advanced features

## Development Guidelines

To maintain compatibility for future migration:

1. **Model Synchronization**: When models change in the Supabase schema, update corresponding SQLAlchemy models
2. **API Compatibility**: Ensure new APIs follow RESTful conventions matching the current Supabase structure
3. **Feature Parity**: Implement any new Supabase features in FastAPI to maintain compatibility

## Getting Started

### Prerequisites

- Python 3.9+
- PostgreSQL 13+
- Supabase project

### Setup

1. Create a virtual environment:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Set up environment variables (copy `.env.example` to `.env` and fill in values)

4. Run the development server:
   ```bash
   uvicorn app.main:app --reload
   ```

5. Access the API documentation at http://localhost:8000/docs

## Integration with Flutter

The Flutter app is designed with a service layer abstraction that will allow for a seamless migration:

- Clean architecture repositories and use cases provide an abstraction layer
- Future development will include a gateway pattern for selective routing
- UI components are decoupled from the backend implementation

## Notes for Future Migration

When ready to integrate in Phase 6 (post-launch):

1. Update repository implementations to point to FastAPI endpoints
2. Implement gateway pattern for selective routing
3. Maintain Supabase for authentication initially
4. Gradually migrate critical business logic
5. Add comprehensive testing for all data flows

## Contact

For questions about the backend architecture, contact the development team.