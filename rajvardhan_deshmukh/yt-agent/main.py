# main.py

from dotenv import load_dotenv
load_dotenv()
from flow import build_flow


def main():
    shared = {}  # Shared Store
    flow = build_flow()

    flow.run(shared)


if __name__ == "__main__":
    main()
