# nodes/review.py
# User review and feedback node

import json
from datetime import datetime
from nodes.base import BaseAppNode
from utilities import call_llm
from prompts import SCENE_PLANNER_PROMPT


class ReviewNode(BaseAppNode):
    """Allow user to review and provide feedback on the scene plan."""
    
    def __init__(self):
        super().__init__()
        from nodes.manim_coder import ManimCoderNode
        self.next(ManimCoderNode(), "approved")
        self.next(self, "iterate")
    
    def exec(self, shared):
        scene_plan = shared["scene_plan"]
        
        self._display_plan(scene_plan)
        
        print("\nOptions:")
        print("  [a] Approve and continue to code generation")
        print("  [i] Request improvements (you can add your feedback)")
        print("  [q] Quit")
        
        choice = input("\nYour choice: ").strip().lower()
        
        if choice == 'a':
            print("\n✅ [ReviewNode] Plan approved by user")
            return "approved"
        
        elif choice == 'i':
            print("\n" + "="*70)
            print("💬 PROVIDE YOUR IMPROVEMENTS")
            print("="*70)
            print("Enter your feedback/improvements below.")
            print("(Be specific about what you want to add or change)")
            print("-"*70)
            
            feedback = input("\nYour feedback: ").strip()
            
            if not feedback:
                print("⚠️  No feedback provided. Returning to review.")
                return "iterate"
            
            with open("llm_outputs.txt", "a", encoding="utf-8") as f:
                f.write(f"\n{'='*80}\n")
                f.write(f"TIMESTAMP: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
                f.write(f"USER FEEDBACK (Human-in-the-Loop)\n")
                f.write(f"{'='*80}\n\n")
                f.write(f"{feedback}\n")
                f.write(f"\n{'='*80}\n\n")
            
            print("\n🔄 Re-running LLM with your feedback...")
            
            plan_summary = f"Previous plan had {len(shared['scene_plan'])} characters."
            
            compacted_prompt = f"""{SCENE_PLANNER_PROMPT}

## REVISION CONTEXT (Compacted)
{plan_summary}

## USER FEEDBACK (Priority)
{feedback}

Apply the user's feedback while maintaining all previous content structure.
"""
            
            improved_plan = call_llm(
                compacted_prompt,
                json.dumps(shared["draft_output"], indent=2)
            )
            
            shared["scene_plan"] = improved_plan
            print("\n✨ [ReviewNode] Scene plan updated based on your feedback!\n")
            
            return "iterate"
        
        elif choice == 'q':
            print("\n👋 [ReviewNode] User quit review")
            exit(0)
        
        else:
            print("\n⚠️  Invalid choice. Please try again.")
            return "iterate"
    
    def _display_plan(self, scene_plan):
        print("\n" + "="*70)
        print("📋 SCENE PLAN REVIEW")
        print("="*70)
        print(scene_plan)
        print("\n" + "="*70)
