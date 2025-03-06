import React from 'react'
import {Link} from 'react-router'

export default function Sidebar() {
  return (
    <ul>
      <li><Link to="employees">Employees</Link></li>
      <li><Link to="attendance">Attendance</Link></li>
      {/* <li><Link to="expenses">Expenses</Link></li> */}
    </ul>
  )
}
