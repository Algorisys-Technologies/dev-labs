import React, { useEffect } from 'react';
import { Form, redirect, useLoaderData } from 'react-router';
import { employeeApi } from '../api/store';
import { expenseApi } from '../api/expense';
// import { employeeApi } from '../api/store';
import ExpenseList from './component/expenses-list';

export async function expenseLoader({params}) {
    console.log('Loading Expenses...');
    const empId = params.empId
    const data = await expenseApi.fetchExpenses(empId);
    // const employee = await employeeApi.fetchEmployee(empId);
    return {data, empId};
  }
  

export async function expenseAction({ request }) {
  const form = await request.formData();
  console.log('Form submit:', Object.fromEntries(form));

  const amount = form.get('amount');
  const description = form.get('desc');
  const date = form.get('date');
  const action = form.get('formAction');
  const empId = form.get('empId');

  console.log('Submitting form data:', { amount, description, date, action, empId });

  if (action === 'new-expense') {
    console.log("in action new expense")
    await expenseApi.addExpense(empId, { amount, description, date });
  }
  return redirect(`/expenses/${empId}`);
}
export default function Expense() {
    const {data, empId} = useLoaderData();
    return (
      <div>
        <h3>Employee Expenses</h3>
        {/* <h1>Name: {employee?.firstName} {employee?.lastName}</h1> */}
        {/* {employee ? (
          <h1>Name: {employee.firstName} {employee.lastName}</h1>
        ) : (
          <h1>Loading employee name...</h1>  // Handle missing employee
        )} */}
        <Form method='post'>
        <input type="hidden" name="empId" value={empId} />
          <div>
            <label>Amount</label>
            <input type="text" name="amount" placeholder="Enter amount..." required />
          </div>
          <div>
            <label>Description</label>
            <input type="text" name="desc" placeholder="Enter description..." required />
          </div>
          <div>
            <label>Date</label>
            <input type="date" name="date" required />
          </div>
          <div>
          <button type="submit" name="formAction" value="new-expense">Add Expense</button>
          </div>
        </Form>
        <ExpenseList data={data} />
      </div>
    );
  }
