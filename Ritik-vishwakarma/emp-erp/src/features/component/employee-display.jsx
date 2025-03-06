import React from 'react'

export default function EmployeeDisplay({emp}) {
  return (
    <>
      <td>{emp.firstname}
      <input type='hidden' value={emp.id} />
      </td>
      <td>{emp.lastname}</td>
      <td>{emp.temp?.toString()}</td>
    </>
  )
}
