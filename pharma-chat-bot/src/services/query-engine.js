import { connection } from '../db/duckdb.js';

export const runQuery = async (sql) => {
  try {
    const result = await connection.run(sql);
    console.log(result.rowCount, 'rows returned');
    let data = await result.getRows();
    return data;
  } catch (err) {
    console.error('Error running query:', err);
    throw err
    // return { error: err.message };
  }
};