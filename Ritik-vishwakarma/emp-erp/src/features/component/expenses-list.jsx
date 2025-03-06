import React from 'react';

export default function ExpenseList({ data }) {
    console.log(data, "from data")

  return (
    <div>
      <table border="1" cellPadding="10">
        <thead>
          <tr>
            <th>Id</th>
            <th>Amount</th>
            <th>Description</th>
            <th>Date</th>
          </tr>
        </thead>
        <tbody>
          {data.map((expense) => (
            <React.Fragment key={expense.id}>
              <tr>
                <td>{expense.id}</td>
                <td>{expense.amount}</td>
                <td>{expense.description}</td>
                <td>{expense.date}</td>
              </tr>
            </React.Fragment>
          ))}
        </tbody>
      </table>
    </div>
  );
}
