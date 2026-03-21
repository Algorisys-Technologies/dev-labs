export const Providers = [
  { label: "OpenAI", value: "openai" },
  { label: "Google", value: "google" },
  { label: "Claude", value: "claude" },
];

export const LLM_MODELS = [
  { provider: "openai", label: "GPT-4o", value: "gpt-4o" },
  { provider: "openai", label: "GPT-4o Mini", value: "gpt-4o-mini" },
  { provider: "openai", label: "GPT-4 Turbo", value: "gpt-4-turbo" },
  { provider: "openai", label: "GPT-3.5 Turbo", value: "gpt-3.5-turbo" },
  { provider: "google", label: "Gemini 1.5 Pro", value: "gemini-1.5-pro" },
  { provider: "google", label: "Gemini 1.5 Flash", value: "gemini-1.5-flash" },
  {
    provider: "claude",
    label: "Claude 3.5 Sonnet",
    value: "claude-3-5-sonnet-20240620",
  },
  {
    provider: "claude",
    label: "Claude 3 Opus",
    value: "claude-3-opus-20240229",
  },
  {
    provider: "claude",
    label: "Claude 3 Haiku",
    value: "claude-3-haiku-20240307",
  },
];

export const DEFAULT_LLM_MODEL = "gpt-4o";
export const DEFAULT_PROVIDER = "openai";