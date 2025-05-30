# Dayliz - Q-Commerce Grocery Delivery App

A full-stack, scalable, and cost-efficient q-commerce mobile app for grocery delivery in India, supporting real-time order tracking, optimized for Indian users.

## Project Structure

After cleanup, the project is organized as follows:

- **Dayliz_App/**: Main Flutter application with the complete source code
- **backend/**: FastAPI backend for the application
- **docs/**: Project documentation including roadmaps and data standards
- **.github/**: GitHub workflows and configuration
- **Dayliz_App.zip**: A backup archive of the main Flutter application

## Tech Stack

### Frontend
- **Framework**: Flutter (Android-first, Play Store-ready)
- **State Management**: Riverpod
- **Performance**: Lazy loading, image caching, async pagination
- **Offline Support**: Product catalog and user session caching
- **Notifications**: Supabase real-time triggers

### Backend
- **Framework**: FastAPI (Python)
- **Database**: Supabase PostgreSQL
- **Auth**: Supabase Auth
- **Payment**: Razorpay + COD
- **Geolocation**: Google Maps API
- **Hosting**: DigitalOcean (backend), Supabase (database & auth)

## Project Setup

### Prerequisites
- Flutter SDK (2.10.0+)
- Python 3.8+
- Supabase account
- Razorpay account
- Google Maps API key

### Backend Setup
1. Navigate to backend directory:
   ```
   cd backend
   ```

2. Create virtual environment:
   ```
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. Install dependencies:
   ```
   pip install -r requirements.txt
   ```

4. Create a `.env` file based on `.env.example` and fill in your credentials.

5. Run the server:
   ```
   uvicorn app.main:app --reload
   ```

6. API documentation will be available at `http://localhost:8000/docs`.

### Frontend Setup
1. Navigate to frontend directory:
   ```
   cd Dayliz_App
   ```

2. Install Flutter dependencies:
   ```
   flutter pub get
   ```

3. Create a `.env` file in the frontend directory with your API keys.

4. Run the app:
   ```
   flutter run
   ```

## Features

The app includes user flows for customers, administrators, and delivery drivers.

## Contributors
- [Your Name](https://github.com/LazyDev-01)

## License
MIT 