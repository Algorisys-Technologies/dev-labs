import React, { useState } from 'react';
import { Link, useSubmit } from 'react-router';
import EmployeeDisplay from './employee-display';
import EmployeeEditForm from './employee-edit-form';
// import EmployeeExpenses from './expense-edit-form';      
import Expense from '../expense';

export default function EmployeeList({ data }) {
  const [editingId, setEditingId] = useState(null);
  const [editingExpenseId, setEditingExpenseId] = useState(null);

  const submit = useSubmit();

  const handleDelete = (empId) => {
    alert(empId);
    submit(
      { empId: empId, formAction: 'delete-employee' },
      { action: '/employees', method: 'post' }
    );
  };

  const handleEditToggle = (empId) => {
    setEditingId(editingId === empId ? null : empId);
  };

  const handleExpenseEditToggle = (empId) => {
    setEditingExpenseId(editingExpenseId === empId ? null : empId);
  };

  // Function to add an expense for an employee
  const handleAddExpense = (empId, newExpense) => {
    setExpenses((prevExpenses) => ({
      ...prevExpenses,
      [empId]: [...(prevExpenses[empId] || []), { id: Date.now(), ...newExpense }]
    }));
  };

  return (
    <div>
      <table border="1" cellPadding="10">
        <thead>
          <tr>
            <th>First Name</th>
            <th>Last Name</th>
            <th>Temporary?</th>
            <th>Actions</th>
            <th>Expenses</th>
          </tr>
        </thead>
        <tbody>
          {data.map((emp) => (
            <React.Fragment key={emp.id}>
              <tr>
                {editingId === emp.id ? (
                  <EmployeeEditForm emp={emp} onSave={() => setEditingId(null)} />
                ) : (
                  <EmployeeDisplay emp={emp} />
                )}
                <td>
                  <button onClick={() => handleDelete(emp.id)} type="button">X</button>
                  <button onClick={() => handleEditToggle(emp.id)} type="button">
                    {editingId === emp.id ? 'Cancel' : 'Edit'}
                  </button>
                </td> 
                <td><Link to={`/expenses/${emp.id}`}>Add Expenses</Link></td>
              </tr>

            </React.Fragment>
          ))}
        </tbody>
      </table>
    </div>
  );
}
