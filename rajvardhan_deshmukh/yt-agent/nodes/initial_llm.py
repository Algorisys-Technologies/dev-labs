# nodes/initial_llm.py
# Initial LLM processing node

import json
from nodes.base import BaseAppNode
from utilities import call_llm, extract_json
from prompts import INITIAL_PROMPT


class InitialLLMNode(BaseAppNode):
    """Generate initial content outline via LLM."""
    
    def __init__(self):
        super().__init__()
        from nodes.scene_planner import ScenePlannerNode
        self.next(ScenePlannerNode(), "next")

    def exec(self, shared):
        user_query = shared["user_query"]

        raw_output = call_llm(INITIAL_PROMPT, user_query)

        try:
            draft_output = extract_json(raw_output)
        except json.JSONDecodeError:
            raise ValueError(
                f"InitialLLMNode JSON parse failed:\n{raw_output}"
            )

        shared["draft_output"] = draft_output
        print("[InitialLLMNode] Draft generated via LLM")
        return "next"
