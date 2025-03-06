let expenses = [
    { id: "1", empId: "1", amount: 50, description: "Lunch", date: "2024-03-01" },
    { id: "2", empId: "2", amount: 30, description: "Taxi", date: "2024-03-02" },
  ];
  
  const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
  
  export const expenseApi = {
    async fetchExpenses(empId) {
      await delay(300);
      return expenses.filter((exp) => exp.empId === empId);
    },
  
    async getExpense(id) {
      await delay(300);
      return expenses.find((exp) => exp.id === id) || null;
    },
  
    async addExpense(empId, expenseData) {
      await delay(300);
      const newExpense = {
        id: Date.now().toString(),
        empId,
        ...expenseData,
      };
      expenses.push(newExpense);
      return newExpense;
    },
  
    async updateExpense(id, updatedData) {
      await delay(300);
      expenses = expenses.map((exp) =>
        exp.id === id ? { ...exp, ...updatedData } : exp
      );
      return expenses.find((exp) => exp.id === id) || null;
    },
  
    async deleteExpense(id) {
      await delay(300);
      expenses = expenses.filter((exp) => exp.id !== id);
      return true;
    },
  };
  

