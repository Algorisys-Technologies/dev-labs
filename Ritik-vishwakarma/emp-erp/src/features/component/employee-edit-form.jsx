import React from 'react'
import { useFetcher } from 'react-router';
export default function EmployeeEditForm({emp}) {
  const fetcher = useFetcher();
  
  console.log("Editing: ", emp);
  return (
    <td>
      <fetcher.Form method="post">
        <td>{emp.firstname}
          <input type='hidden' name="empId" value={emp.id} />
          <input type='text' name="firstname" defaultValue={emp.firstname} />
        </td>
        <td><input type='text'  name="lastname" defaultValue={emp.lastname} /></td>
        <td> <input type="checkbox" name="temp" defaultChecked={emp.temp}  /></td>
        <td><button type="submit" name="formAction" value="edit-employee">Submit</button></td>
      </fetcher.Form>
    </td>
  )
}
