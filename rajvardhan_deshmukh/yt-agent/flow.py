# flow.py

from pocketflow import Flow
from nodes import UserInputNode


def build_flow():
    return Flow(start=UserInputNode())
