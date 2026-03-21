import dotenv from "dotenv";
dotenv.config();

import { DEFAULT_LLM_MODEL, DEFAULT_PROVIDER } from "./llm-models.js";

const config = {
  aiProviderOrchestrationAPIURL:
    process.env.AI_PROVIDER_ORCHESTRATION_API_URL || "",
  aiProviderOrchestrationAPIKey:
    process.env.AI_PROVIDER_ORCHESTRATION_API_KEY || "",
  headers: {
    "Content-Type": "application/json",
    Authorization: `Bearer ${
      process.env.AI_PROVIDER_ORCHESTRATION_API_KEY || ""
    }`,
  },
};

/**
 * Reusable function to call AI Provider Orchestration API
 * @param modelName - The model to use for generation
 * @param provider - The provider to use
 * @param systemPrompt - System prompt object with role and content
 * @param userPrompt - User prompt object with role and content
 * @returns Object containing parsed result and token usage
 */
export async function callAiProviderOrchestration(
  userPrompt, //: { role = DEFAULT_LLM_MODEL; content = DEFAULT_LLM_MODEL | any },
  systemPrompt, //: { role = DEFAULT_LLM_MODEL; content = DEFAULT_LLM_MODEL | any },
  modelName = DEFAULT_LLM_MODEL,
  provider = DEFAULT_PROVIDER,
  
) {
  const response = await fetch(
    config.aiProviderOrchestrationAPIURL + "/ai/generate",
    {
      method: "POST",
      headers: config.headers,
      body: JSON.stringify({
        model: modelName,
        provider: provider,
        prompts: [systemPrompt, userPrompt],
      }),
    },
  );

  if (!response.ok) {
    const errorBody = await response.text();
    console.error("AI API Error Body:", errorBody);
    throw new Error(
      `AI Provider Orchestration API error: ${response.status} ${response.statusText} - ${errorBody}`,
    );
  }

  const res = await response.json();

  return res;
}