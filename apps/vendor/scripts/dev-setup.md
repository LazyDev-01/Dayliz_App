# Vendor Panel Development Setup

## Prerequisites

1. **Node.js 16+** installed
2. **Supabase project** set up (use dayliz-dev project)
3. **Test vendor account** created

## Setup Steps

### 1. Install Dependencies
```bash
cd apps/vendor
npm install
```

### 2. Environment Configuration
```bash
cp .env.example .env
```

Update `.env` with your Supabase credentials:
```env
VITE_SUPABASE_URL=https://zdezerezpbeuebnompyj.supabase.co
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key_here
VITE_BACKEND_TYPE=supabase
VITE_ENABLE_REALTIME=true
VITE_DEV_MODE=true
```

### 3. Database Setup

#### Create Test Vendor in Supabase

1. **Run the SQL script** in Supabase SQL Editor:
   ```sql
   -- Copy and paste the content from scripts/setup-test-vendor.sql
   ```

2. **Create Auth User** in Supabase Dashboard:
   - Go to Authentication > Users
   - Click "Add User"
   - Email: `vendor@test.com`
   - Password: `vendor123456`
   - Click "Create User"

### 4. Start Development Server
```bash
npm run dev
```

The vendor panel will be available at: `http://localhost:5173`

## Test Login Credentials

### Option 1: Existing Vendor (Recommended)
- **Email**: `vendor@dayliz.com`
- **Password**: `[You need to set this in Supabase Dashboard]`

### Option 2: New Test Vendor
- **Email**: `testvendor@dayliz.com`
- **Password**: `[You need to create this user in Supabase Dashboard]`

### How to Set Up Test Credentials:

1. **Go to Supabase Dashboard**: https://supabase.com/dashboard
2. **Select dayliz-dev project**
3. **Go to Authentication > Users**
4. **For existing user (vendor@dayliz.com)**:
   - Click on the user
   - Click "Reset Password"
   - Set password to: `vendor123456`
5. **OR create new user (testvendor@dayliz.com)**:
   - Click "Add User"
   - Email: `testvendor@dayliz.com`
   - Password: `vendor123456`
   - Click "Create User"

## Development Workflow

### 1. Authentication Testing
- Test login/logout functionality
- Verify session persistence
- Check error handling for invalid credentials

### 2. Service Layer Testing
- Verify Supabase connection
- Test vendor data fetching
- Check real-time subscriptions (when implemented)

### 3. UI/UX Testing
- Test mobile responsiveness
- Verify navigation and routing
- Check Ant Design theme consistency

## Troubleshooting

### Common Issues

1. **Supabase Connection Error**
   - Verify VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY
   - Check if Supabase project is active
   - Ensure RLS policies allow vendor access

2. **Login Failed**
   - Verify test vendor exists in vendors table
   - Check if auth.users entry exists
   - Ensure vendor status is 'active'

3. **Build Errors**
   - Clear node_modules and reinstall: `rm -rf node_modules && npm install`
   - Check TypeScript errors: `npm run type-check`
   - Verify all imports are correct

### Debug Mode

Enable debug mode in `.env`:
```env
VITE_DEV_MODE=true
VITE_LOG_LEVEL=debug
```

This will show:
- Service layer logs
- Authentication state changes
- API request/response details

## Next Steps

After successful setup:

1. **Test Authentication Flow**
   - Login with test credentials
   - Verify dashboard loads
   - Test logout functionality

2. **Implement Order Management**
   - Real-time order subscriptions
   - Order status updates
   - Audio notifications

3. **Add Product Management**
   - Product listing
   - Inventory updates
   - Bulk operations

## Production Deployment

For production deployment:

1. Update environment variables for production Supabase project
2. Build the application: `npm run build`
3. Deploy to your hosting platform (Vercel, Netlify, etc.)
4. Configure proper domain and SSL

## Support

If you encounter issues:
1. Check the browser console for errors
2. Verify Supabase project settings
3. Review the service layer implementation
4. Test with different browsers
