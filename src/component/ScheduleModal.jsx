import React, { useState } from "react";

const ScheduleModal = ({ onClose }) => {
  const [schedules, setSchedules] = useState([
    { id: 1, scheduleDate: "", qty: "" }
  ]);

  const handleScheduleChange = (index, field, value) => {
    const updatedSchedules = [...schedules];
    updatedSchedules[index][field] = value;
    setSchedules(updatedSchedules);

    // Add new row if the last row is filled
    if (index === schedules.length - 1 && value !== "") {
      setSchedules([...schedules, { id: schedules.length + 1, scheduleDate: "", qty: "" }]);
    }
  };

  return (
    <div className="fixed inset-0 flex justify-center items-center bg-black bg-transparent">
      <div className="bg-gray-900 text-white p-6 rounded-lg w-1/3">
        <h2 className="text-lg font-bold mb-4">Add Schedule</h2>
        <table className="w-full border border-gray-600 text-center">
          <thead>
            <tr className="bg-gray-800">
              <th className="p-2 border">Sno.</th>
              <th className="p-2 border">Schedule Date</th>
              <th className="p-2 border">Qty</th>
            </tr>
          </thead>
          <tbody>
            {schedules.map((schedule, index) => (
              <tr key={schedule.id} className="border border-gray-600">
                <td className="p-2 border">{index + 1}</td>
                <td className="p-2 border">
                  <input
                    type="date"
                    className="bg-gray-700 p-2 w-full rounded"
                    value={schedule.scheduleDate}
                    onChange={(e) => handleScheduleChange(index, "scheduleDate", e.target.value)}
                  />
                </td>
                <td className="p-2 border">
                  <input
                    type="number"
                    className="bg-gray-700 p-2 w-full rounded"
                    value={schedule.qty}
                    onChange={(e) => handleScheduleChange(index, "qty", e.target.value)}
                  />
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        <div className="mt-4 flex justify-center">
          <button 
            className="bg-green-500 px-4 py-2 rounded"
            onClick={() => onClose(false)} // Closes the modal
          >
            Add Schedule
          </button>
        </div>
      </div>
    </div>
  );
};

export default ScheduleModal;
