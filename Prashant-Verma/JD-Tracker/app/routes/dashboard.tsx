import { Link, Outlet } from "@remix-run/react";
import { employees, leaveApplications, candidates, attendanceRecords } from "~/utils/dummyData";
import { toast } from "react-hot-toast";

export default function Dashboard() {
  // Get today's date in YYYY-MM-DD format
  const today = new Date().toISOString().split('T')[0];

  // Filter today's approved leaves
  const todayLeaves = leaveApplications.filter(
    (leave) => leave.status === "Approved" &&
      leave.startDate <= today &&
      leave.endDate >= today
  );

  // Combine with employee names
  const leavesWithNames = todayLeaves.map((leave) => {
    const employee = employees.find((emp) => emp.id === leave.employeeId);
    return {
      ...leave,
      employeeName: employee ? employee.name : "Unknown",
    };
  });

  const pendingCandidates = candidates.filter(
    (candidate) => candidate.status === "Pending"
  );

  // Calculate Employee of the Month (simple logic based on attendance)
  const employeeOfTheMonth = () => {
    // Count present days for each employee this month
    const currentMonth = new Date().getMonth() + 1;
    const monthlyAttendance = attendanceRecords.filter(record => {
      const recordMonth = parseInt(record.date.split('-')[1]);
      return recordMonth === currentMonth && record.status === "Present";
    });

    const employeeAttendanceCount: Record<number, number> = {};
    monthlyAttendance.forEach(record => {
      employeeAttendanceCount[record.employeeId] =
        (employeeAttendanceCount[record.employeeId] || 0) + 1;
    });

    // Find employee with most attendance
    let topEmployeeId = 0;
    let maxDays = 0;
    Object.entries(employeeAttendanceCount).forEach(([id, days]) => {
      if (days > maxDays) {
        maxDays = days;
        topEmployeeId = parseInt(id);
      }
    });

    return employees.find(emp => emp.id === topEmployeeId) || employees[0];
  };

  const topEmployee = employeeOfTheMonth();

  const handleTimeIn = () => {
    const currentTime = new Date().toLocaleTimeString();
    toast.success(`Time in recorded at ${currentTime}`, {
      position: "top-center",
      duration: 4000,
      icon: '🕒',
      style: {
        background: '#f0fff4',
        color: '#2f855a',
        border: '1px solid #c6f6d5',
      },
    });
  };

  const handleTimeOut = () => {
    const currentTime = new Date().toLocaleTimeString();
    toast.success(`Time out recorded at ${currentTime}`, {
      position: "top-center",
      duration: 4000,
      icon: '🕒',
      style: {
        background: '#fff5f5',
        color: '#c53030',
        border: '1px solid #fed7d7',
      },
    });
  };


  return (
    <div className="flex bg-gray-100">

      {/* Main Content */}
      <div className="flex-1 overflow-auto">
        <main className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
          <div className="flex items-center justify-center space-x-4">
            <button
              onClick={handleTimeIn}
              className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-green-600 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500"
            >
              <svg
                className="-ml-1 mr-2 h-5 w-5"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth="2"
                  d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
              In Time
            </button>
            <div className="ml-4 flex items-center text-sm text-gray-600">
              <svg
                className="mr-1.5 h-5 w-5 text-gray-400"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth="2"
                  d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
              {new Date().toLocaleTimeString()}
            </div>
            <button
              onClick={handleTimeOut}
              className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
            >
              <svg
                className="-ml-1 mr-2 h-5 w-5"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth="2"
                  d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
              Out Time
            </button>
            <div className="ml-4 flex items-center text-sm text-gray-600">
              <svg
                className="mr-1.5 h-5 w-5 text-gray-400"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth="2"
                  d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
              {new Date().toLocaleTimeString()}
            </div>
          </div>
          <div className="px-4 py-6 sm:px-0">
            {/* Stats Cards */}
            <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
              {/* Total Employees */}
              <div className="bg-white overflow-hidden shadow rounded-lg">
                <div className="px-4 py-5 sm:p-6">
                  <div className="flex items-center">
                    <div className="flex-shrink-0 bg-indigo-500 rounded-md p-3">
                      <svg
                        className="h-6 w-6 text-white"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                      >
                        <path
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth="2"
                          d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
                        />
                      </svg>
                    </div>
                    <div className="ml-5 w-0 flex-1">
                      <dt className="text-sm font-medium text-gray-500 truncate">
                        Total Employees
                      </dt>
                      <dd className="flex items-baseline">
                        <div className="text-2xl font-semibold text-gray-900">
                          {employees.length}
                        </div>
                      </dd>
                    </div>
                  </div>
                </div>
              </div>

              {/* On Leave Today */}
              <div className="bg-white overflow-hidden shadow rounded-lg">
                <div className="px-4 py-5 sm:p-6">
                  <div className="flex items-center">
                    <div className="flex-shrink-0 bg-green-500 rounded-md p-3">
                      <svg
                        className="h-6 w-6 text-white"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                      >
                        <path
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth="2"
                          d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
                        />
                      </svg>
                    </div>
                    <div className="ml-5 w-0 flex-1">
                      <dt className="text-sm font-medium text-gray-500 truncate">
                        On Leave Today
                      </dt>
                      <dd className="flex items-baseline">
                        <div className="text-2xl font-semibold text-gray-900">
                          {todayLeaves.length}
                        </div>
                      </dd>
                    </div>
                  </div>
                </div>
              </div>



              {/* Employee of the Month */}
              <div className="bg-white overflow-hidden shadow rounded-lg">
                <div className="px-4 py-5 sm:p-6">
                  <div className="flex items-center">
                    <div className="flex-shrink-0 bg-purple-500 rounded-md p-3">
                      <svg
                        className="h-6 w-6 text-white"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                      >
                        <path
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth="2"
                          d="M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.519 4.674a1 1 0 00.95.69h4.915c.969 0 1.371 1.24.588 1.81l-3.976 2.888a1 1 0 00-.363 1.118l1.518 4.674c.3.922-.755 1.688-1.538 1.118l-3.976-2.888a1 1 0 00-1.176 0l-3.976 2.888c-.783.57-1.838-.197-1.538-1.118l1.518-4.674a1 1 0 00-.363-1.118l-3.976-2.888c-.784-.57-.38-1.81.588-1.81h4.914a1 1 0 00.951-.69l1.519-4.674z"
                        />
                      </svg>
                    </div>
                    <div className="ml-5 w-0 flex-1">
                      <dt className="text-sm font-medium text-gray-500 truncate">
                        Employee of the Month
                      </dt>
                      <dd className="flex items-baseline">
                        <div className="text-lg font-semibold text-gray-900 truncate">
                          {topEmployee.name}
                        </div>
                      </dd>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Today's Leaves and Employee of the Month Sections */}
            <div className="mt-8 grid grid-cols-1 gap-6 lg:grid-cols-2">
              {/* Today's Leaves */}
              <div>
                <h2 className="text-lg font-medium text-gray-900 mb-4">
                  Today's Leaves
                </h2>
                <div className="bg-white shadow overflow-hidden sm:rounded-lg">
                  {leavesWithNames.length > 0 ? (
                    <ul className="divide-y divide-gray-200">
                      {leavesWithNames.map((leave) => (
                        <li key={leave.id}>
                          <div className="px-4 py-4 sm:px-6">
                            <div className="flex items-center justify-between">
                              <p className="text-sm font-medium text-indigo-600 truncate">
                                {leave.employeeName}
                              </p>
                              <div className="ml-2 flex-shrink-0 flex">
                                <p className="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800">
                                  {leave.type} Leave
                                </p>
                              </div>
                            </div>
                            <div className="mt-2 sm:flex sm:justify-between">
                              <div className="sm:flex">
                                <p className="flex items-center text-sm text-gray-500">
                                  {leave.startDate === leave.endDate
                                    ? leave.startDate
                                    : `${leave.startDate} to ${leave.endDate}`}
                                </p>
                              </div>
                              <div className="mt-2 flex items-center text-sm text-gray-500 sm:mt-0">
                                <svg
                                  className="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400"
                                  fill="none"
                                  viewBox="0 0 24 24"
                                  stroke="currentColor"
                                >
                                  <path
                                    strokeLinecap="round"
                                    strokeLinejoin="round"
                                    strokeWidth="2"
                                    d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
                                  />
                                </svg>
                                <p>
                                  {leave.startDate === leave.endDate
                                    ? "1 day"
                                    : `${Math.ceil(
                                      (new Date(leave.endDate).getTime() -
                                        new Date(leave.startDate).getTime()) /
                                      (1000 * 60 * 60 * 24)
                                    ) + 1} days`}
                                </p>
                              </div>
                            </div>
                          </div>
                        </li>
                      ))}
                    </ul>
                  ) : (
                    <div className="px-4 py-12 text-center">
                      <svg
                        className="mx-auto h-12 w-12 text-gray-400"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                      >
                        <path
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth="1"
                          d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
                        />
                      </svg>
                      <h3 className="mt-2 text-sm font-medium text-gray-900">
                        No leaves today
                      </h3>
                      <p className="mt-1 text-sm text-gray-500">
                        All employees are present at work today.
                      </p>
                    </div>
                  )}
                </div>
              </div>

              {/* Employee of the Month */}
              <div>
                <h2 className="text-lg font-medium text-gray-900 mb-4">
                  Employee of the Month
                </h2>
                <div className="bg-white shadow overflow-hidden sm:rounded-lg">
                  <div className="px-4 py-5 sm:p-6">
                    <div className="flex items-center">
                      <div className="flex-shrink-0 h-16 w-16 rounded-full bg-purple-100 flex items-center justify-center">
                        <span className="text-purple-600 text-2xl font-medium">
                          {topEmployee.name.charAt(0)}
                        </span>
                      </div>
                      <div className="ml-4">
                        <h3 className="text-lg font-medium text-gray-900">
                          {topEmployee.name}
                        </h3>
                        <p className="text-sm text-gray-500">
                          {topEmployee.position}
                        </p>
                        <div className="mt-2 flex items-center text-sm text-gray-500">
                          <svg
                            className="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke="currentColor"
                          >
                            <path
                              strokeLinecap="round"
                              strokeLinejoin="round"
                              strokeWidth="2"
                              d="M21 13.255A23.931 23.931 0 0112 15c-3.183 0-6.22-.62-9-1.745M16 6V4a2 2 0 00-2-2h-4a2 2 0 00-2 2v2m4 6h.01M5 20h14a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
                            />
                          </svg>
                          {topEmployee.department}
                        </div>
                      </div>
                    </div>
                    <div className="mt-6">
                      <h4 className="text-sm font-medium text-gray-900">
                        Performance Highlights
                      </h4>
                      <ul className="mt-2 space-y-2">
                        <li className="flex items-start">
                          <svg
                            className="flex-shrink-0 h-5 w-5 text-green-500"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke="currentColor"
                          >
                            <path
                              strokeLinecap="round"
                              strokeLinejoin="round"
                              strokeWidth="2"
                              d="M5 13l4 4L19 7"
                            />
                          </svg>
                          <p className="ml-2 text-sm text-gray-700">
                            Perfect attendance this month
                          </p>
                        </li>
                        <li className="flex items-start">
                          <svg
                            className="flex-shrink-0 h-5 w-5 text-green-500"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke="currentColor"
                          >
                            <path
                              strokeLinecap="round"
                              strokeLinejoin="round"
                              strokeWidth="2"
                              d="M5 13l4 4L19 7"
                            />
                          </svg>
                          <p className="ml-2 text-sm text-gray-700">
                            Consistently high performance ratings
                          </p>
                        </li>
                        <li className="flex items-start">
                          <svg
                            className="flex-shrink-0 h-5 w-5 text-green-500"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke="currentColor"
                          >
                            <path
                              strokeLinecap="round"
                              strokeLinejoin="round"
                              strokeWidth="2"
                              d="M5 13l4 4L19 7"
                            />
                          </svg>
                          <p className="ml-2 text-sm text-gray-700">
                            Recognized by multiple clients
                          </p>
                        </li>
                      </ul>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Recent Activity */}
            <div className="mt-8">
              <h2 className="text-lg font-medium text-gray-900 mb-4">
                Recent Activity
              </h2>
              <div className="bg-white shadow overflow-hidden sm:rounded-md">
                <ul className="divide-y divide-gray-200">
                  <li>
                    <div className="px-4 py-4 sm:px-6">
                      <div className="flex items-center justify-between">
                        <p className="text-sm font-medium text-indigo-600 truncate">
                          New candidate applied
                        </p>
                        <div className="ml-2 flex-shrink-0 flex">
                          <p className="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800">
                            Pending
                          </p>
                        </div>
                      </div>
                      <div className="mt-2 sm:flex sm:justify-between">
                        <div className="sm:flex">
                          <p className="flex items-center text-sm text-gray-500">
                            Alice Smith for Senior Developer
                          </p>
                        </div>
                        <div className="mt-2 flex items-center text-sm text-gray-500 sm:mt-0">
                          <svg
                            className="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke="currentColor"
                          >
                            <path
                              strokeLinecap="round"
                              strokeLinejoin="round"
                              strokeWidth="2"
                              d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
                            />
                          </svg>
                          <p>June 14, 2023</p>
                        </div>
                      </div>
                    </div>
                  </li>
                  {/* Add more activity items */}
                </ul>
              </div>
            </div>
          </div>
        </main>
      </div>
    </div>
  );
}