import { DuckDBInstance } from '@duckdb/node-api';

const instance = await DuckDBInstance.create(':memory:');
export const connection = await instance.connect();

export const initDB = async () => {
  await connection.run(`
    CREATE TABLE sales AS SELECT * FROM './data/sales.csv';
    CREATE TABLE inventory AS SELECT * FROM './data/inventory.csv';
    CREATE TABLE cashflow AS SELECT * FROM './data/cashflow.csv';
  `);
};