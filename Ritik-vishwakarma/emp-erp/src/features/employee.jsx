import React from 'react'
import {Form, useLoaderData} from 'react-router'
import { employeeApi } from  "../api/store";
import EmployeeList from './component/employee-list';
// import EmployeeExpenses from './component/expense-edit-form';

export async function employeeLoader() {
  console.log("Employee Loader....");
  const data = await employeeApi.fetchEmployees();
  // console.log(data);
  return data;
}

export async function employeeAction({request}) {
  
  const form = await request.formData();
  console.log("Form submit: ", form);
  const firstname = form.get("firstname");
  const lastname = form.get("lastname");
  const temp = form.get("temp");

  const action = form.get("formAction");
  const empId = form.get("empId");

  console.log("Submitting form data: ", {firstname: firstname, lastname: lastname, temp, action, empId});

  if (action === "new-employee") {
    await employeeApi.addEmployee(firstname, lastname, temp);
  }
  if (action === "delete-employee") {
    await employeeApi.deleteEmployee(empId);
  }
  if (action === "edit-employee") {
    await employeeApi.updateEmployee(empId, {empId, firstname: firstname, lastname: lastname, temp});
  }
}

export default function Employee() { 
  const employees = useLoaderData();
  // console.log("Render: ", employees);
  return (
    <div>
      <h2>Employee Register</h2>
      <Form method="post">
        <div>
          <label>First Name</label>
          <input type="text" name="firstname" placeholder='Enter first name...' />
        </div>
        <div>
          <label>Last Name</label>
          <input type="text" name="lastname" placeholder='Enter last name...' />
        </div>
        
        <div>
          <label>Temporary</label>
          <input type="checkbox" name="temp"  />
        </div>
        
        <div>
          <button type="submit" name="formAction" value="new-employee">Submit</button>
        </div>
      </Form>

      <h2>All Employees</h2>
      <EmployeeList data = {employees}/>
    </div>
  )
}
