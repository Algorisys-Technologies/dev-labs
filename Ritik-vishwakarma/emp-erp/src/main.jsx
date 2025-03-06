import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
// import { BrowserRouter, Routes, Route } from "react-router";
import {Route, RouterProvider, createBrowserRouter} from 'react-router'
import './index.css'
import App from './app.jsx'
import About from './about.jsx'
import Employee, { employeeAction, employeeLoader } from './features/employee.jsx'
import Attendance from './features/attendance.jsx'
import Expense, { expenseAction, expenseLoader } from './features/expense.jsx'
// import EmployeeExpenses from './features/component/employee-expense.jsx'


const router = createBrowserRouter([
  {
    path: "/",
    element: <App />,
    children:[{
      path: "employees",
      element: <Employee />,
      action: employeeAction,
      loader: employeeLoader
    },
    {
      path: "attendance",
      element: <Attendance />
    },
    {
      path: '/expenses/:empId',
      element: <Expense />,
      action: expenseAction, 
      loader: expenseLoader
    },
  ]
  },
  {
    path: "/about",
    element: <About />
  },
])

createRoot(document.querySelector("#root")).render(
  <StrictMode>
    <RouterProvider router = {router} />
  </StrictMode>
)