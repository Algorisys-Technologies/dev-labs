import { initDB } from './db/duckdb.js';

(async () => {
  await initDB();
})();