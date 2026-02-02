# nodes/scene_planner.py
# Scene planning node

import json
from nodes.base import BaseAppNode
from utilities import call_llm, parse_narrations
from prompts import SCENE_PLANNER_PROMPT


class ScenePlannerNode(BaseAppNode):
    """Generate scene-by-scene plan from content outline."""
    
    def __init__(self):
        super().__init__()
        from nodes.voice_over import VoiceOverNode
        self.next(VoiceOverNode(), "next")

    def exec(self, shared):
        draft = shared["draft_output"]

        raw_output = call_llm(
            SCENE_PLANNER_PROMPT,
            json.dumps(draft, indent=2)
        )

        shared["scene_plan"] = raw_output
        
        narrations = parse_narrations(raw_output)
        shared["narrations"] = narrations
        
        print(f"[ScenePlannerNode] Scene plan generated via LLM")
        print(f"[ScenePlannerNode] Parsed {len(narrations)} narration blocks")
        return "next"
