# nodes/user_input.py
# User input node

from nodes.base import BaseAppNode


class UserInputNode(BaseAppNode):
    """Get video topic from user input."""
    
    def __init__(self):
        super().__init__()
        # Import here to avoid circular imports
        from nodes.initial_llm import InitialLLMNode
        self.next(InitialLLMNode(), "next")

    def exec(self, shared):
        shared["user_query"] = input("Enter video topic: ")
        print("[UserInputNode] User query stored")
        return "next"
