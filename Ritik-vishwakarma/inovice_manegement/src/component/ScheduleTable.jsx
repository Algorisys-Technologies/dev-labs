import { useState } from "react";
import { useNavigate } from "react-router-dom";


const ScheduleTable = () => {
  const [schedules, setSchedules] = useState([{ id: 1, date: "", qty: "" }]);

  const addSchedule = () => {
    setSchedules([...schedules, { id: schedules.length + 1, date: "", qty: "" }]);
  };

  const handleChange = (index, field, value) => {
    const newSchedules = [...schedules];
    newSchedules[index][field] = value;
    setSchedules(newSchedules);
  };
  

  return (
    <div className="p-4 bg-gray-900 text-white rounded-md">
      <table className="w-full border border-gray-700">
        <thead>
          <tr className="bg-gray-800">
            <th className="p-2 border border-gray-700">Sno.</th>
            <th className="p-2 border border-gray-700">Schedule Date</th>
            <th className="p-2 border border-gray-700">Qty.</th>
          </tr>
        </thead>
        <tbody>
          {schedules.map((schedule, index) => (
            <tr key={schedule.id} className="border border-gray-700">
              <td className="p-2 text-center">{schedule.id}</td>
              <td className="p-2">
                <input
                  type="date"
                  value={schedule.date}
                  onChange={(e) => handleChange(index, "date", e.target.value)}
                  className="w-full p-2 bg-gray-800 border border-gray-700 rounded"
                />
              </td>
              <td className="p-2">
                <input
                  type="number"
                  value={schedule.qty}
                  onChange={(e) => handleChange(index, "qty", e.target.value)}
                  className="w-full p-2 bg-gray-800 border border-gray-700 rounded"
                />
              </td>
            </tr>
          ))}
        </tbody>
      </table>

      <button
        onClick={addSchedule}
        className="mt-4 bg-blue-500 px-4 py-2 rounded w-full hover:bg-blue-600"
      >
        Add Schedule
      </button>
    </div>
  );
};

export default ScheduleTable;
