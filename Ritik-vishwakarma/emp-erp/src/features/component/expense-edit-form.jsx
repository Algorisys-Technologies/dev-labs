import React from "react";
import { useFetcher } from "react-router-dom";

export default function EmployeeExpenses({ empId, expenses, isEditing }) {
  const fetcher = useFetcher();

  // Filter expenses based on empId
  const employeeExpenses = expenses.filter((exp) => exp.empId === empId);

  return (
    <div>
      <h4>Expenses</h4>
      {employeeExpenses.length === 0 ? (
        <p>No expenses added yet.</p>
      ) : (
        <ul>
          {employeeExpenses.map((exp) => (
            <li key={exp.id}>
              <fetcher.Form method="post">
                <input type="hidden" name="expenseId" value={exp.id} />
                <input type="hidden" name="empId" value={empId} />

                <input type="number" name="amount" defaultValue={exp.amount} />
                <input type="text" name="description" defaultValue={exp.description} />
                <input type="date" name="date" defaultValue={exp.date} />

                <button type="submit" name="formAction" value="edit-expense">
                  Save
                </button>
                <button type="submit" name="formAction" value="delete-expense">
                  Delete
                </button>
              </fetcher.Form>
            </li>
          ))}
        </ul>
      )}

      {isEditing && (
        <>
          <h4>Add New Expense</h4>
          <fetcher.Form method="post">
            <input type="hidden" name="empId" value={empId} />
            <input type="number" name="amount" placeholder="Amount" required />
            <input type="text" name="description" placeholder="Description" required />
            <input type="date" name="date" required />
            <button type="submit" name="formAction" value="add-expense">
              Add Expense
            </button>
          </fetcher.Form>
        </>
      )}
    </div>
  );
}
