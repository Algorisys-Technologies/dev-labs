import React, { useState } from "react";

const TaxModal = ({ onClose, onSave, basicAmount }) => {
  const [taxes, setTaxes] = useState([
    { id: 1, taxName: "", calculatedAs: "", taxRate: "", taxAmount: 0 },
  ]);

  const handleChange = (index, field, value) => {
    const newTaxes = [...taxes];
    newTaxes[index][field] = value;

    // Calculate tax amount
    if (field === "taxRate" || field === "calculatedAs") {
      const rate = parseFloat(newTaxes[index].taxRate) || 0;
      if (newTaxes[index].calculatedAs === "Percentage") {
        newTaxes[index].taxAmount = (rate / 100) * basicAmount;
      } else if (newTaxes[index].calculatedAs === "Fixed") {
        newTaxes[index].taxAmount = rate;
      }
    }

    setTaxes(newTaxes);
  };

  const addTaxRow = () => {
    setTaxes([...taxes, { id: taxes.length + 1, taxName: "", calculatedAs: "", taxRate: "", taxAmount: 0 }]);
  };

  const handleSave = () => {
    onSave(taxes); // Send tax data to parent
    onClose(false);
  };

  return (
    <div className="fixed inset-0 flex justify-center items-center bg-black bg-transparent">
      <div className="bg-gray-900 text-white p-6 rounded-lg w-1/3">
        <h2 className="text-lg font-bold mb-4">Add Tax</h2>
        <table className="w-full border border-gray-600 text-center">
          <thead>
            <tr className="bg-gray-800">
              <th className="p-2 border">Sno.</th>
              <th className="p-2 border">Tax Name</th>
              <th className="p-2 border">Calculated As</th>
              <th className="p-2 border">Tax Rate</th>
              <th className="p-2 border">Tax Amount</th>
            </tr>
          </thead>
          <tbody>
            {taxes.map((tax, index) => (
              <tr key={index} className="border border-gray-600">
                <td className="p-2 border">{tax.id}</td>
                <td className="p-2 border">
                  <select className="bg-gray-700 p-2 w-full rounded" value={tax.taxName} onChange={(e) => handleChange(index, "taxName", e.target.value)}>
                    <option value="">-- Select Tax --</option>
                    <option value="GST">IGST</option>
                    <option value="VAT">CGST</option>
                    <option value="VAT">Discount</option>
                  </select>
                </td>
                <td className="p-2 border">
                  <select className="bg-gray-700 p-2 w-full rounded" value={tax.calculatedAs} onChange={(e) => handleChange(index, "calculatedAs", e.target.value)}>
                    <option value="">-- Select --</option>
                    <option value="Percentage">Percentage</option>
                    <option value="Fixed">Fixed</option>
                  </select>
                </td>
                <td className="p-2 border">
                  <input type="number" className="bg-gray-700 p-2 w-full rounded" value={tax.taxRate} onChange={(e) => handleChange(index, "taxRate", e.target.value)} />
                </td>
                <td className="p-2 border">{tax.taxAmount.toFixed(2)}</td>
              </tr>
            ))}
          </tbody>
        </table>
        <div className="mt-4 flex justify-between">
          <button className="bg-gray-700 px-4 py-2 rounded" onClick={addTaxRow}>
            Add Tax
          </button>
          <button className="bg-green-500 px-4 py-2 rounded" onClick={handleSave}>
            Save
          </button>
          <button className="bg-red-500 px-4 py-2 rounded" onClick={() => onClose(false)}>
            Close
          </button>
        </div>
      </div>
    </div>
  );
};

export default TaxModal;
