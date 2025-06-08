# Dayliz Admin Panel

Admin dashboard for Dayliz Q-commerce application built with Next.js, Tailwind CSS, and ShadCN UI.

## Features

- Product management (CRUD operations)
- Order management with status updates
- User management
- Dashboard with key metrics
- Admin activity logs

## Tech Stack

- **Frontend**: Next.js, React, Tailwind CSS, ShadCN UI
- **Backend**: Supabase
- **State Management**: React Query
- **Form Validation**: Zod
- **Authentication**: Supabase Auth

## Getting Started

### Prerequisites

- Node.js 18+ and npm
- Supabase account and project

### Installation

1. Clone the repository
2. Install dependencies:
```bash
cd apps/admin
npm install
```

3. Create a `.env.local` file with your Supabase credentials:
```
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
```

4. Start the development server:
```bash
npm run dev
```

### Build for Production

```bash
npm run build
npm run start
```

## Project Structure

- `/app` - Next.js app router pages and layouts
- `/components` - Reusable UI components
- `/lib` - Utility functions and helpers
- `/types` - TypeScript type definitions
- `/hooks` - Custom React hooks
- `/public` - Static assets

## Authentication

This admin panel is protected with Supabase Auth and requires admin privileges. Users must have the `is_admin` field set to `true` in the Supabase database. 