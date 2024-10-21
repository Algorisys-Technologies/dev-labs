import { clerkMiddleware, createRouteMatcher } from "@clerk/nextjs/server";
import { NextResponse } from "next/server";

// Define protected routes
const isProtectedRoute = createRouteMatcher([
  "/dashboard(.*)",
  "/organization(.*)",
  "/select-org(.*)",
]);

export default clerkMiddleware((auth, req) => {
  const { userId, orgId } = auth();

  // If the user is trying to access a protected route
  if (isProtectedRoute(req)) {
    auth().protect(); // Redirect unauthenticated users to the sign-in page
  }

  // If the user is authenticated but no organization is selected, redirect to /select-org
  if (userId && !orgId && req.nextUrl.pathname !== "/select-org") {
    return NextResponse.redirect(new URL("/select-org", req.url));
  }

  if (userId && orgId && req.nextUrl.pathname === "/") {
    return NextResponse.redirect(new URL(`/organization/${orgId}`, req.url));
  }

  // If the user is already on /select-org or an org-specific page, avoid redirecting back
  if (userId && orgId && req.nextUrl.pathname === "/select-org") {
    return NextResponse.redirect(new URL(`/organization/${orgId}`, req.url));
  }

  // Proceed if no redirection is needed
  return NextResponse.next();
});

export const config = {
  matcher: [
    // Skip Next.js internals and all static files
    "/((?!_next|[^?]*\\.(?:html?|css|js(?!on)|jpe?g|webp|png|gif|svg|ttf|woff2?|ico|csv|docx?|xlsx?|zip|webmanifest)).*)",
    // Always run for API routes
    "/(api|trpc)(.*)",
  ],
};
