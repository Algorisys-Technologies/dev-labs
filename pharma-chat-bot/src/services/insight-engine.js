import { callAiProviderOrchestration } from './ai-provider-orchestration.js';
export const generateInsights = async (question, data) => {
  const prompt = `
You are a pharma business analyst.

User Question: ${question}
Data: ${JSON.stringify(data).slice(0, 2000)}

Provide:
1. Key Insights
2. Risks
3. Recommendations
4. Actions
`;

  const res = await callAiProviderOrchestration(
    { role: 'user', content: prompt }
  );

  return res.response;
};