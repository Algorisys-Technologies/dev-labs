import React, { useState } from "react";
import ScheduleModal from "./ScheduleModal";
import AddTax from "./AddTax"

const PurchaseOrder = () => {
    // const [tax,setTax]=useState(false);
    const [items, setItems] = useState([
      { id: 1, selectedItem: "", qty: "", rate: "", basicAmount: 0, tax: 0, netAmount: 0 }
    ]);
    const [activeIndex, setActiveIndex] = useState(null);
    const [taxIndex, setTaxIndex] = useState(null);
    const handleShow = (index) => {
      setActiveIndex(index);
    };

    console.log(items, "from item")
  
    const closeModal = () => {
      setActiveIndex(null);
    };
  
    const handleTax = (index) => {
      setTaxIndex(index);
    };
  
    const handleItemChange = (index, value) => {
      const updatedItems = [...items];
      updatedItems[index].selectedItem = value;
      setItems(updatedItems);
  
      if (index === items.length - 1 && value !== "") {
        setItems([...items, { id: items.length + 1, selectedItem: "", qty: "", rate: "", basicAmount: 0, tax: 0, netAmount: 0 }]);
      }
    };
  
    const handleInputChange = (index, field, value) => {
      const updatedItems = [...items];
      updatedItems[index][field] = value;
  
      // Recalculate basic amount and net amount
      const qty = parseFloat(updatedItems[index].qty) || 0;
      const rate = parseFloat(updatedItems[index].rate) || 0;
      updatedItems[index].basicAmount = qty * rate;
      updatedItems[index].netAmount = updatedItems[index].basicAmount + updatedItems[index].tax; // Assuming tax is added later
  
      setItems(updatedItems);
    };
  
    const handleTaxSave = (index, taxData) => {
      const updatedItems = [...items];
      const totalTax = taxData.reduce((sum, tax) => sum + tax.taxAmount, 0);
      updatedItems[index].tax = totalTax;
      updatedItems[index].netAmount = updatedItems[index].basicAmount + totalTax;
      setItems(updatedItems);
      setTaxIndex(null);
    };
  
    const totalBasic = items.reduce((sum, item) => sum + item.basicAmount, 0);
    const totalTax = items.reduce((sum, item) => sum + item.tax, 0);
    const totalNet = items.reduce((sum, item) => sum + item.netAmount, 0);
  return (
    <div className="bg-gray-900 text-white p-6 min-h-screen">
      <div className="flex justify-center items-center gap-4 mb-4">
        <div>
          <button className="bg-gray-700 px-4 py-2 rounded">Purchase Order</button>
          <button className="bg-gray-700 px-4 py-2 rounded ml-2">GRN</button>
          <button className="bg-gray-700 px-4 py-2 rounded ml-2">Material Issue</button>
          <button className="bg-gray-700 px-4 py-2 rounded ml-2">Report</button>
        </div>
      </div>
      <hr />
      <div className="flex justify-center items-center gap-4 mt-4">
        <button className="bg-green-600 px-4 py-2 rounded">New</button>
        <button className="bg-blue-600 px-4 py-2 rounded">Save</button>
        <button className="bg-yellow-600 px-4 py-2 rounded">Search</button>
        <button className="bg-red-600 px-4 py-2 rounded">Delete</button>
      </div>
      
      <div className="bg-gray-800 p-4 rounded-lg">
        <div className="grid grid-cols-2 gap-4 mb-4">
          <div>
            <label className="block">Po No</label>
            <input type="text" className="bg-gray-700 p-2 w-full rounded" defaultValue="test-1" />
          </div>
          <div>
            <label className="block">Po Date</label>
            <input type="date" className="bg-gray-700 p-2 w-full rounded" defaultValue="2025-03-14" />
          </div>
        </div>
        <div>
          <label className="block">Customer Name</label>
          <select className="bg-gray-700 p-2 w-full rounded">
            <option>Select One Customer</option>
            <option>John doe</option>
            <option> Dominick</option>
            <option>Ashley Torres</option>
            <option>Ruben Marsh</option>
            <option>Remi Foley</option>
            <option>John doe</option>
          </select>
        </div>
      </div>

      <div className="bg-gray-900 text-white p-6 min-h-screen">
      <div className="bg-gray-800 p-4 rounded-lg mt-4">
        <table className="w-full text-white">
          <thead>
            <tr>
              <th>Sno.</th>
              <th>Item Name</th>
              <th>Qty</th>
              <th>Schedule</th>
              <th>Rate</th>
              <th>Basic Amount</th>
              <th>Tax</th>
              <th>Net Amount</th>
            </tr>
          </thead>
          <tbody>
            {items.map((item, index) => (
              <tr key={item.id}>
                <td>{index + 1}</td>
                <td>
                  <select
                    className="bg-gray-700 p-2 rounded"
                    value={item.selectedItem}
                    onChange={(e) => handleItemChange(index, e.target.value)}
                  >
                    <option value="">Select One Item</option>
                    <option value="Rubber">Rubber</option>
                    <option value="Product A">Product A</option>
                    <option value="Product B">Product B</option>
                    <option value="Product C">Product C</option>
                  </select>
                </td>
                <td>
                  <input
                    type="number"
                    placeholder="qty"
                    className="bg-gray-700 p-2 w-full rounded"
                    value={item.qty}
                    onChange={(e) => handleInputChange(index, "qty", e.target.value)}
                  />
                </td>
                <td>
                  <button className="bg-gray-700 px-4 py-2 rounded" onClick={() => handleShow(index)}>
                    Add Schedule
                  </button>
                </td>
                <td>
                  <input
                    type="number"
                    placeholder="rate"
                    className="bg-gray-700 p-2 w-full rounded"
                    value={item.rate}
                    onChange={(e) => handleInputChange(index, "rate", e.target.value)}
                  />
                </td>
                <td>{item.basicAmount.toFixed(2)}</td>
                <td>
                  <button className="bg-gray-700 px-4 py-2 rounded" onClick={() => handleTax(index)}>
                    Add Tax
                  </button>
                  {taxIndex === index && (
                    <AddTax onClose={() => setTaxIndex(null)} onSave={(taxData) => handleTaxSave(index, taxData)} basicAmount={totalBasic.toFixed(2)}/>
                  )}
                </td>
                <td>{item.netAmount.toFixed(2)}</td>
              </tr>
            ))}
          </tbody>
        </table>
        <div className="mt-4 text-right">
          <p>Total Basic: {totalBasic.toFixed(2)}</p>
          <p>Total Tax: {totalTax.toFixed(2)}</p>
          <p>Total Net Amount: {totalNet.toFixed(2)}</p>
        </div>
      </div>

      {activeIndex !== null && <ScheduleModal onClose={closeModal} />}
    </div>
    </div>
  );
};

export default PurchaseOrder;
