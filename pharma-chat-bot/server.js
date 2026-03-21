import Fastify from 'fastify';
import dotenv from 'dotenv';
import chatRoutes from './src/routes/chat.js';
import { initDB } from './src/db/duckdb.js';
dotenv.config();

const app = Fastify({ logger: true });

await initDB();
app.register(chatRoutes, { prefix: '/api' });

app.listen({ port: 3000 }, (err, address) => {
  if (err) throw err;
  console.log(`Server running at ${address}`);
});