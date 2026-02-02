# =========================
# REINFORCEMENT LEARNING WITH VISUALIZATION
# =========================
# Q-Learning on a 4x4 Grid World
# Run this file to see training progress charts

# =========================
# ENVIRONMENT
# =========================

GRID_SIZE = 4
GOAL = (3, 3)

def step(state, action):
    row, col = state

    # Actions: 0=UP, 1=DOWN, 2=LEFT, 3=RIGHT
    if action == 0:   row -= 1
    elif action == 1: row += 1
    elif action == 2: col -= 1
    elif action == 3: col += 1

    # Keep agent inside grid
    row = max(0, min(row, GRID_SIZE - 1))
    col = max(0, min(col, GRID_SIZE - 1))

    next_state = (row, col)

    if next_state == GOAL:
        return next_state, +10, True   # success
    else:
        return next_state, -1, False   # time penalty

# =========================
# AGENT MEMORY (Q-TABLE)
# =========================

import random

ACTIONS = 4

Q = {}
for i in range(GRID_SIZE):
    for j in range(GRID_SIZE):
        Q[(i, j)] = [0.0] * ACTIONS

alpha = 0.1    # learning rate
gamma = 0.9    # future reward importance
epsilon = 0.2  # exploration probability

def choose_action(state):
    if random.random() < epsilon:
        return random.randint(0, ACTIONS - 1)  # explore
    else:
        return Q[state].index(max(Q[state]))   # exploit

# =========================
# TRAINING (with tracking)
# =========================

EPISODES = 500

episode_rewards = []
episode_steps = []

print("Training Q-Learning agent...")
for episode in range(EPISODES):
    state = (0, 0)
    done = False
    total_reward = 0
    steps = 0

    while not done:
        action = choose_action(state)
        next_state, reward, done = step(state, action)

        best_next = max(Q[next_state])
        Q[state][action] += alpha * (
            reward + gamma * best_next - Q[state][action]
        )

        state = next_state
        total_reward += reward
        steps += 1

    episode_rewards.append(total_reward)
    episode_steps.append(steps)

    if (episode + 1) % 100 == 0:
        avg_reward = sum(episode_rewards[-100:]) / 100
        avg_steps = sum(episode_steps[-100:]) / 100
        print(f"Episode {episode+1}: Avg Reward = {avg_reward:.1f}, Avg Steps = {avg_steps:.1f}")

# =========================
# TEST
# =========================

state = (0, 0)
path = [state]

while state != GOAL:
    action = Q[state].index(max(Q[state]))
    state, _, _ = step(state, action)
    path.append(state)

print(f"\n✅ Learned Path: {path}")
print(f"✅ Optimal path length: {len(path) - 1} steps")

# =========================
# VISUALIZATION
# =========================

import matplotlib.pyplot as plt
import numpy as np

fig, axes = plt.subplots(2, 2, figsize=(12, 10))
fig.suptitle('Q-Learning Training Progress', fontsize=14, fontweight='bold')

# 1. Reward per episode
ax1 = axes[0, 0]
ax1.plot(episode_rewards, alpha=0.3, color='blue', linewidth=0.5)
window = 20
smoothed = np.convolve(episode_rewards, np.ones(window)/window, mode='valid')
ax1.plot(range(window-1, len(episode_rewards)), smoothed, color='red', linewidth=2, label=f'{window}-episode avg')
ax1.set_xlabel('Episode')
ax1.set_ylabel('Total Reward')
ax1.set_title('Total Reward per Episode')
ax1.axhline(y=4, color='green', linestyle='--', alpha=0.5, label='Optimal (10 - 6 steps = 4)')
ax1.legend()
ax1.grid(True, alpha=0.3)

# 2. Steps per episode
ax2 = axes[0, 1]
ax2.plot(episode_steps, alpha=0.3, color='green', linewidth=0.5)
smoothed_steps = np.convolve(episode_steps, np.ones(window)/window, mode='valid')
ax2.plot(range(window-1, len(episode_steps)), smoothed_steps, color='darkgreen', linewidth=2, label=f'{window}-episode avg')
ax2.axhline(y=6, color='red', linestyle='--', alpha=0.5, label='Optimal (6 steps)')
ax2.set_xlabel('Episode')
ax2.set_ylabel('Steps to Goal')
ax2.set_title('Steps per Episode (Lower = Better)')
ax2.legend()
ax2.grid(True, alpha=0.3)

# 3. Q-value heatmap
ax3 = axes[1, 0]
q_max = np.zeros((GRID_SIZE, GRID_SIZE))
for i in range(GRID_SIZE):
    for j in range(GRID_SIZE):
        q_max[i, j] = max(Q[(i, j)])
im = ax3.imshow(q_max, cmap='RdYlGn', interpolation='nearest')
ax3.set_title('Max Q-Value per State\n(Green = High Value, closer to goal)')
ax3.set_xlabel('Column')
ax3.set_ylabel('Row')
for i in range(GRID_SIZE):
    for j in range(GRID_SIZE):
        ax3.text(j, i, f'{q_max[i,j]:.1f}', ha='center', va='center', fontsize=10, fontweight='bold')
plt.colorbar(im, ax=ax3)

# 4. Learned policy (arrows)
ax4 = axes[1, 1]
ax4.set_xlim(-0.5, GRID_SIZE - 0.5)
ax4.set_ylim(GRID_SIZE - 0.5, -0.5)
ax4.set_aspect('equal')
ax4.set_title('Learned Policy\n(Arrows = Best Action per State)')
ax4.set_xlabel('Column')
ax4.set_ylabel('Row')

for i in range(GRID_SIZE + 1):
    ax4.axhline(i - 0.5, color='black', linewidth=0.5)
    ax4.axvline(i - 0.5, color='black', linewidth=0.5)

arrow_dirs = {0: (0, -0.3), 1: (0, 0.3), 2: (-0.3, 0), 3: (0.3, 0)}

for i in range(GRID_SIZE):
    for j in range(GRID_SIZE):
        if (i, j) == GOAL:
            ax4.add_patch(plt.Circle((j, i), 0.3, color='gold', zorder=5))
            ax4.text(j, i, 'G', ha='center', va='center', fontsize=12, fontweight='bold', zorder=6)
        else:
            best_action = Q[(i, j)].index(max(Q[(i, j)]))
            dx, dy = arrow_dirs[best_action]
            ax4.arrow(j, i, dx, dy, head_width=0.15, head_length=0.1, fc='blue', ec='blue')

ax4.plot(0, 0, 'go', markersize=15, label='Start (0,0)')
path_cols = [p[1] for p in path]
path_rows = [p[0] for p in path]
ax4.plot(path_cols, path_rows, 'r--', linewidth=2, alpha=0.7, label='Learned Path')
ax4.legend(loc='upper left')

plt.tight_layout()
plt.savefig('rl_training_progress.png', dpi=150, bbox_inches='tight')
print("\n📊 Visualization saved to 'rl_training_progress.png'")
plt.show()
