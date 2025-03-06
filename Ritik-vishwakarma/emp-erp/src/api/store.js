let employees = [
  { id: "1", firstname: "John", lastname: "Doe", temp: false },
  { id: "2", firstname: "Jane", lastname: "Smith", temp: true },
];

let expenses = [
  { id: "1", firstname: "John", lastname: "Doe", temp: false },
  { id: "2", firstname: "Jane", lastname: "Smith", temp: true },
];

const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

export const employeeApi = {
  async fetchEmployees() {
    await delay(300);
    return employees;
  },

  async getEmployee(id) {
    await delay(300);
    return employees.find((emp) => emp.id === id) || null;
  },

  async addEmployee(firstname, lastname, temp) {
    await delay(300);
    const newEmployee = {
      id: Date.now().toString(),
      firstname,
      lastname,
      temp,
    };
    employees.push(newEmployee);
    return newEmployee;
  },

  async updateEmployee(id, updatedData) {
    await delay(300);
    employees = employees.map((emp) =>
      emp.id === id ? { ...emp, ...updatedData } : emp
    );

    console.log("DATA STORE EDIT: ", id, employees);
    return employees.find((emp) => emp.id === id) || null;
  },

  async deleteEmployee(id) {
    await delay(300);
    employees = employees.filter((emp) => emp.id !== id);
    return true;
  },
};
