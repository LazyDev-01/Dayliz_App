import { createMiddlewareClient } from '@supabase/auth-helpers-nextjs'
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export async function middleware(req: NextRequest) {
  // Development mode - bypass authentication checks
  if (process.env.NODE_ENV !== 'production') {
    return NextResponse.next();
  }

  // Production mode with missing env vars - bypass for safety
  if (!process.env.NEXT_PUBLIC_SUPABASE_URL || !process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY) {
    console.warn('Missing Supabase environment variables. Authentication disabled.');
    return NextResponse.next();
  }

  // For login page, always allow access
  if (req.nextUrl.pathname.startsWith('/login')) {
    return NextResponse.next();
  }

  // Create Supabase client for auth checks
  const res = NextResponse.next()
  const supabase = createMiddlewareClient({ req, res })

  // Get the user's session
  const { data: { session } } = await supabase.auth.getSession()

  // If there's no session, redirect to login
  if (!session) {
    const url = req.nextUrl.clone()
    url.pathname = '/login'
    return NextResponse.redirect(url)
  }

  // Return the response with the session
  return res
}

// Apply this middleware to all admin dashboard routes except login, static assets, etc
export const config = {
  matcher: [
    '/dashboard/:path*',
    '/products/:path*',
    '/orders/:path*',
    '/users/:path*',
    '/settings/:path*',
    '/((?!login|unauthorized|_next/static|_next/image|favicon.ico).*)',
  ],
} 