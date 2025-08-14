import {
  Links,
  Meta,
  Outlet,
  Scripts,
  ScrollRestoration,
  useMatches,
} from "@remix-run/react";
import type { LinksFunction } from "@remix-run/node";
import { useState } from "react";
import Header from "~/components/Header";
import Sidebar from "~/components/Sidebar";
import "./tailwind.css";
import { Toaster } from "react-hot-toast";

export const links: LinksFunction = () => [
  { rel: "preconnect", href: "https://fonts.googleapis.com" },
  {
    rel: "preconnect",
    href: "https://fonts.gstatic.com",
    crossOrigin: "anonymous",
  },
  {
    rel: "stylesheet",
    href: "https://fonts.googleapis.com/css2?family=Inter:ital,opsz,wght@0,14..32,100..900;1,14..32,100..900&display=swap",
  },
];

export function Layout({ children }: { children: React.ReactNode }) {
  const [isSidebarOpen, setIsSidebarOpen] = useState(true);
  const matches = useMatches();

  // Check if current route is login or index
  const hideLayout = matches.some(match =>
    match.id === "routes/login" || match.id === "routes/_index"
  );

  const toggleSidebar = () => {
    setIsSidebarOpen(!isSidebarOpen);
  };

  return (
    <html lang="en">
      <head>
        <meta charSet="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <Meta />
        <Links />
      </head>
      <body>
        {hideLayout ? (
          <main>{children}</main>
        ) : (
          <div className="flex h-screen bg-gray-100">
            <Sidebar isOpen={isSidebarOpen} />
            <div className="flex-1 overflow-auto">
              <Header isSidebarOpen={isSidebarOpen} toggleSidebar={toggleSidebar} />
              <main className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
                {children}
              </main>
            </div>
          </div>
        )}
        <ScrollRestoration />
        <Toaster />
        <Scripts />
      </body>
    </html>
  );
}

export default function App() {
  return <Outlet />;
}