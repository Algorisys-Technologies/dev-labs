import { generateSQL } from  '../services/sql-agent.js';
import { runQuery } from '../services/query-engine.js';
import { generateInsights } from '../services/insight-engine.js';

export default async function routes(fastify) {
  fastify.post('/chat', async (req, reply) => {
    const { question } = req.body;

    // Step 1: Convert to SQL
    let sql = await generateSQL(question);
    sql = sql.replace(/```sql|```/g, '').trim(); // Clean SQL if wrapped in code block
    console.log('Generated SQL:', sql);
    // Step 2: Run Query
    const data = await runQuery(sql);

    // Step 3: Generate Insights
    const insights = await generateInsights(question, data);

    return {
      question,
      sql,
      data,
      insights
    };
  });
}