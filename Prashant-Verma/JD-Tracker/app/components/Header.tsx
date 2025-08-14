import { useState } from 'react';
import { Link } from "@remix-run/react";

export default function Header({ isSidebarOpen, toggleSidebar }: {
    isSidebarOpen: boolean,
    toggleSidebar: () => void
}) {
    const [showNotifications, setShowNotifications] = useState(false);

    // Dummy notification data
    const notifications = [
        {
            id: 1,
            title: "Rahul candidate assigned to you",
            description: "New candidate assigned for interview process",
            date: "2 hours ago",
            read: false
        },
        {
            id: 2,
            title: "Rahul candidate Joined Successfully",
            description: "Candidate has completed onboarding process",
            date: "1 day ago",
            read: true
        },
        {
            id: 3,
            title: "Rahul candidate 90 days over",
            description: "Follow-up for incentive processing required",
            date: "3 days ago",
            read: true
        }
    ];

    const unreadCount = notifications.filter(n => !n.read).length;

    return (
        <header className="bg-white shadow-sm">
            <div className="max-w-7xl mx-auto py-4 px-4 sm:px-6 lg:px-8">
                <div className="flex items-center justify-between">
                    {/* Left side - toggle button and title */}
                    <div className="flex items-center space-x-4">
                        <button
                            onClick={toggleSidebar}
                            className="p-2 rounded-md text-gray-500 hover:text-gray-600 hover:bg-gray-100 focus:outline-none"
                        >
                            {isSidebarOpen ? (
                                <svg
                                    className="h-6 w-6"
                                    fill="none"
                                    viewBox="0 0 24 24"
                                    stroke="currentColor"
                                >
                                    <path
                                        strokeLinecap="round"
                                        strokeLinejoin="round"
                                        strokeWidth={2}
                                        d="M6 18L18 6M6 6l12 12"
                                    />
                                </svg>
                            ) : (
                                <svg
                                    className="h-6 w-6"
                                    fill="none"
                                    viewBox="0 0 24 24"
                                    stroke="currentColor"
                                >
                                    <path
                                        strokeLinecap="round"
                                        strokeLinejoin="round"
                                        strokeWidth={2}
                                        d="M4 6h16M4 12h16M4 18h16"
                                    />
                                </svg>
                            )}
                        </button>
                        <h1 className="text-lg font-semibold text-gray-900">Dashboard</h1>
                    </div>

                    {/* Right side - notification and user profile */}
                    <div className="flex items-center space-x-4 relative">
                        <button
                            onClick={() => setShowNotifications(!showNotifications)}
                            className="p-1 rounded-full text-gray-400 hover:text-gray-500 focus:outline-none relative"
                            aria-label="Notifications"
                        >
                            <svg
                                className="h-6 w-6"
                                fill="none"
                                viewBox="0 0 24 24"
                                stroke="currentColor"
                            >
                                <path
                                    strokeLinecap="round"
                                    strokeLinejoin="round"
                                    strokeWidth="2"
                                    d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"
                                />
                            </svg>
                            {unreadCount > 0 && (
                                <span className="absolute top-0 right-0 inline-flex items-center justify-center px-2 py-1 text-xs font-bold leading-none text-white transform translate-x-1/2 -translate-y-1/2 bg-red-500 rounded-full">
                                    {unreadCount}
                                </span>
                            )}
                        </button>

                        {/* Notification dropdown */}
                        {showNotifications && (
                            <div className="origin-top-right absolute right-0 mt-96 w-72 rounded-md shadow-lg py-1 bg-white ring-1 ring-black ring-opacity-5 focus:outline-none z-50">
                                <div className="px-4 py-2 border-b border-gray-200 flex justify-between items-center">
                                    <h3 className="text-sm font-medium text-gray-900">Notifications</h3>
                                    <button
                                        onClick={() => setShowNotifications(false)}
                                        className="text-gray-400 hover:text-gray-500 focus:outline-none"
                                        aria-label="Close notifications"
                                    >
                                        <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                                        </svg>
                                    </button>
                                </div>
                                <div className="divide-y divide-gray-200 max-h-96 overflow-y-auto">
                                    {notifications.map((notification) => (
                                        <div
                                            key={notification.id}
                                            className={`px-4 py-3 hover:bg-gray-50 ${!notification.read ? 'bg-blue-50' : ''}`}
                                        >
                                            <div className="flex items-start">
                                                <div className="ml-3 flex-1">
                                                    <p className={`text-sm font-medium ${!notification.read ? 'text-blue-800' : 'text-gray-900'}`}>
                                                        {notification.title}
                                                    </p>
                                                    <p className="text-sm text-gray-500">
                                                        {notification.description}
                                                    </p>
                                                    <p className="mt-1 text-xs text-gray-400">
                                                        {notification.date}
                                                    </p>
                                                </div>
                                                {!notification.read && (
                                                    <span className="ml-2 inline-flex items-center justify-center h-2 w-2 rounded-full bg-blue-500"></span>
                                                )}
                                            </div>
                                        </div>
                                    ))}
                                </div>
                                <div className="px-4 py-2 border-t border-gray-200 text-center">
                                    <Link
                                        to="/dashboard"
                                        className="text-sm font-medium text-indigo-600 hover:text-indigo-500"
                                        onClick={() => setShowNotifications(false)}
                                    >
                                        View all notifications
                                    </Link>
                                </div>
                            </div>
                        )}

                        <div className="flex items-center">
                            <div className="ml-3 text-right">
                                <p className="text-sm font-medium text-gray-700">Admin User</p>
                                <p className="text-xs text-gray-500">Administrator</p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </header>
    );
}