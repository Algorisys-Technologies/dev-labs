// app/routes/hrms.jsx
import { Link } from "@remix-run/react";

export default function HRMS() {
  // Dummy data for employees
  const employees = [
    { id: 1, name: "John Doe", department: "IT", position: "Developer" },
    { id: 2, name: "Jane Smith", department: "HR", position: "Manager" },
    { id: 3, name: "Bob Johnson", department: "Finance", position: "Accountant" },
    { id: 4, name: "Alice Brown", department: "Marketing", position: "Specialist" },
    { id: 5, name: "Charlie Wilson", department: "IT", position: "Admin" },
  ];

  // Dummy attendance data
  const attendance = [
    { date: "2023-05-01", day: "Monday", activities: "Project work", inTime: "09:00", outTime: "17:00" },
    { date: "2023-05-02", day: "Tuesday", activities: "Meeting", inTime: "08:30", outTime: "17:30" },
    { date: "2023-05-03", day: "Wednesday", activities: "Training", inTime: "09:15", outTime: "16:45" },
    { date: "2023-05-04", day: "Thursday", activities: "Project work", inTime: "09:00", outTime: "18:00" },
    { date: "2023-05-05", day: "Friday", activities: "Report preparation", inTime: "08:45", outTime: "17:15" },
  ];

  // Dummy leave data
  const onLeaveToday = [
    { id: 2, name: "Jane Smith", leaveType: "Sick Leave", days: 2 },
    { id: 4, name: "Alice Brown", leaveType: "Vacation", days: 5 },
  ];

  return (
    <div className="min-h-screen bg-gray-100">
      <header className="bg-blue-600 text-white p-4">
        <h1 className="text-2xl font-bold">HRMS Module</h1>
        <nav className="flex space-x-4 mt-2">
          <Link to="/" className="hover:underline">Home</Link>
          <Link to="/jd-tracker" className="hover:underline">JD Tracker</Link>
        </nav>
      </header>

      <main className="p-4">
        <div className="max-w-6xl mx-auto grid grid-cols-1 md:grid-cols-2 gap-4">
          {/* Employee Profile Management */}
          <section className="bg-white p-4 rounded shadow">
            <h2 className="text-xl font-semibold mb-2">Employee Profiles</h2>
            <div className="mb-4">
              <input 
                type="text" 
                placeholder="Search employees..." 
                className="w-full p-2 border rounded"
              />
            </div>
            <button className="bg-blue-500 text-white px-4 py-2 rounded mb-4">
              Add New Employee
            </button>
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="bg-gray-200">
                    <th className="p-2 text-left">Name</th>
                    <th className="p-2 text-left">Department</th>
                    <th className="p-2 text-left">Position</th>
                  </tr>
                </thead>
                <tbody>
                  {employees.map(emp => (
                    <tr key={emp.id} className="border-b">
                      <td className="p-2">{emp.name}</td>
                      <td className="p-2">{emp.department}</td>
                      <td className="p-2">{emp.position}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </section>

          {/* Attendance Tracking */}
          <section className="bg-white p-4 rounded shadow">
            <h2 className="text-xl font-semibold mb-2">Attendance Tracking</h2>
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="bg-gray-200">
                    <th className="p-2 text-left">Date</th>
                    <th className="p-2 text-left">Day</th>
                    <th className="p-2 text-left">Activities</th>
                    <th className="p-2 text-left">In-Time</th>
                    <th className="p-2 text-left">Out-Time</th>
                  </tr>
                </thead>
                <tbody>
                  {attendance.map((record, index) => (
                    <tr key={index} className="border-b">
                      <td className="p-2">{record.date}</td>
                      <td className="p-2">{record.day}</td>
                      <td className="p-2">{record.activities}</td>
                      <td className="p-2">{record.inTime}</td>
                      <td className="p-2">{record.outTime}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </section>

          {/* Leave Management */}
          <section className="bg-white p-4 rounded shadow col-span-full">
            <h2 className="text-xl font-semibold mb-2">Leave Management</h2>
            <div className="mb-4">
              <button className="bg-green-500 text-white px-4 py-2 rounded">
                Apply for Leave
              </button>
            </div>
            <h3 className="font-medium mb-2">Employees on Leave Today</h3>
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="bg-gray-200">
                    <th className="p-2 text-left">Employee</th>
                    <th className="p-2 text-left">Leave Type</th>
                    <th className="p-2 text-left">Days</th>
                  </tr>
                </thead>
                <tbody>
                  {onLeaveToday.map(emp => (
                    <tr key={emp.id} className="border-b">
                      <td className="p-2">{emp.name}</td>
                      <td className="p-2">{emp.leaveType}</td>
                      <td className="p-2">{emp.days}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </section>
        </div>
      </main>
    </div>
  );
}