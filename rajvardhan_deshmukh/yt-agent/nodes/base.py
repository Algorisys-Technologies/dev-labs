# nodes/base.py
# Base node class

from pocketflow import Node


class BaseAppNode(Node):
    """Base class for all application nodes."""
    
    def prep(self, shared):
        return shared

    def post(self, shared, prep_res, exec_res):
        return exec_res
