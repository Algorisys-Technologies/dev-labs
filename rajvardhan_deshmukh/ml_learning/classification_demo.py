# =========================
# BINARY CLASSIFICATION: Cats vs Dogs
# =========================
# Using Linear Classifier with Loss Function
# Based on Whisker Length (X1) and Ear Flappiness (X2)

import numpy as np
import matplotlib.pyplot as plt

# =========================
# STEP 1: GATHER DATA
# =========================

# Dogs (+1): High ear flappiness, short whiskers
# Cats (-1): Low ear flappiness, long whiskers

# Format: [Whisker Length (X1), Ear Flappiness (X2), Label]
data = np.array([
    # Dogs (+1) - short whiskers, high ear flappiness
    [2.0, 8.0, +1],
    [2.5, 7.5, +1],
    [3.0, 8.5, +1],
    [1.5, 9.0, +1],
    [2.8, 7.0, +1],
    [3.2, 8.2, +1],
    [2.2, 7.8, +1],
    [1.8, 8.8, +1],
    [2.6, 7.2, +1],
    [3.5, 7.5, +1],
    
    # Cats (-1) - long whiskers, low ear flappiness
    [7.0, 2.0, -1],
    [6.5, 2.5, -1],
    [8.0, 1.5, -1],
    [7.5, 3.0, -1],
    [6.8, 2.2, -1],
    [7.2, 1.8, -1],
    [8.5, 2.8, -1],
    [6.0, 3.5, -1],
    [7.8, 2.0, -1],
    [6.2, 3.2, -1],
])

X = data[:, :2]  # Features: [X1, X2]
y = data[:, 2]    # Labels: +1 or -1

print("=" * 50)
print("STEP 1: DATA GATHERED")
print("=" * 50)
print(f"Total samples: {len(y)}")
print(f"Dogs (+1): {sum(y == 1)}")
print(f"Cats (-1): {sum(y == -1)}")

# =========================
# STEP 2: HYPOTHESIS CLASS
# =========================
# Linear classifier: θ₁X₁ + θ₂X₂ + θ₀ = 0
# Prediction: sign(θ₁X₁ + θ₂X₂ + θ₀)

def hypothesis(X, theta, verbose=False, name=""):
    """
    Linear hypothesis: h(x) = sign(θ₁X₁ + θ₂X₂ + θ₀)
    
    Args:
        X: Data points [N x 2]
        theta: Parameters [θ₀, θ₁, θ₂]
        verbose: If True, print calculation for each point
        name: Name of hypothesis for printing
    
    Returns:
        Predictions: +1 or -1 for each point
    """
    theta_0, theta_1, theta_2 = theta
    
    # Calculate: θ₁X₁ + θ₂X₂ + θ₀
    linear_output = theta_1 * X[:, 0] + theta_2 * X[:, 1] + theta_0
    
    # Apply sign function
    predictions = np.sign(linear_output)
    
    # Show detailed calculations if verbose
    if verbose:
        print(f"\n[DETAILED CALCULATIONS FOR {name}]")
        print(f"   Equation: {theta_1}*X1 + {theta_2}*X2 + {theta_0}")
        print("-" * 80)
        print(f"{'Point':<6} {'X1':>6} {'X2':>6} | {'Calculation':<30} {'Result':>8} | {'Pred':>10}")
        print("-" * 80)
        for i in range(len(X)):
            x1, x2 = X[i, 0], X[i, 1]
            calc = theta_1 * x1 + theta_2 * x2 + theta_0
            calc_str = f"{theta_1}*{x1:.1f} + {theta_2}*{x2:.1f} + {theta_0}"
            pred = int(predictions[i])
            pred_label = "Dog" if pred == 1 else "Cat"
            print(f"  {i+1:<4} {x1:>6.1f} {x2:>6.1f} | {calc_str:<30} = {calc:>6.2f} | {pred:>+2} ({pred_label})")
        print("-" * 80)
    
    return predictions

def get_line_equation_string(theta):
    """Return human-readable equation string"""
    theta_0, theta_1, theta_2 = theta
    return f"{theta_1}·X₁ + {theta_2}·X₂ + {theta_0} = 0"

# =========================
# STEP 3: LOSS FUNCTION
# =========================
# Loss = Number of misclassified points

def calculate_loss(y_true, y_pred):
    """
    Calculate loss as number of mistakes.
    
    Args:
        y_true: Actual labels
        y_pred: Predicted labels
    
    Returns:
        Number of incorrect predictions
    """
    mistakes = np.sum(y_true != y_pred)
    return mistakes

# =========================
# COMPARE H1 vs H2
# =========================

print("\n" + "=" * 50)
print("STEP 2 & 3: HYPOTHESIS COMPARISON")
print("=" * 50)

# Hypothesis 1: y - x + 1 = 0  →  -1·X₁ + 1·X₂ + 1 = 0
# Rearranged: θ₀=1, θ₁=-1, θ₂=1
theta_H1 = [5, -1, 1]

# Hypothesis 2: A BAD line that makes errors on purpose!
# Using: y - 7.3 = 0 (horizontal line at y=7.3)
# This cuts through the dog data - some dogs have ear flappiness < 7.3
# Dogs with X2 = 7.0, 7.2 will be below the line and misclassified as cats!
theta_H2 = [-5.3, 0, 1]

# Test H1
print("\n--- Hypothesis 1 (H1) ---")
print(f"Equation: {get_line_equation_string(theta_H1)}")
print("(This line: X₂ = X₁ - 1)")
predictions_H1 = hypothesis(X, theta_H1, verbose=True, name="H1")
loss_H1 = calculate_loss(y, predictions_H1)
print(f"\nActual Labels: {y.astype(int)}")
print(f"Loss (errors): {loss_H1}")

# Test H2
print("\n" + "=" * 50)
print("--- Hypothesis 2 (H2) - INTENTIONALLY BAD ---")
print(f"Equation: {get_line_equation_string(theta_H2)}")
print("(This line: X2 = 7.3, horizontal - cuts through dog data!)")
predictions_H2 = hypothesis(X, theta_H2, verbose=True, name="H2")
loss_H2 = calculate_loss(y, predictions_H2)
print(f"\nActual Labels: {y.astype(int)}")
print(f"Loss (errors): {loss_H2}")

# Show which points were misclassified
misclassified = np.where(predictions_H2 != y)[0]
if len(misclassified) > 0:
    print(f"\n[X] MISCLASSIFIED POINTS:")
    for idx in misclassified:
        actual = "Dog" if y[idx] == 1 else "Cat"
        predicted = "Dog" if predictions_H2[idx] == 1 else "Cat"
        print(f"   Point {idx+1}: X1={X[idx,0]:.1f}, X2={X[idx,1]:.1f} -> Actually {actual}, Predicted {predicted}")

# Summary
print("\n" + "=" * 50)
print("COMPARISON RESULT")
print("=" * 50)
print(f"H1 Loss: {loss_H1} {'<-- BETTER!' if loss_H1 < loss_H2 else ''}")
print(f"H2 Loss: {loss_H2} {'<-- BETTER!' if loss_H2 < loss_H1 else ''}")

if loss_H1 == 0:
    print("\n[OK] H1 perfectly separates cats and dogs!")
else:
    print(f"\n H1 makes {loss_H1} mistakes")

# =========================
# VISUALIZATION
# =========================

fig, axes = plt.subplots(1, 3, figsize=(15, 5))

# Plot 1: Data only
ax1 = axes[0]
dogs = X[y == 1]
cats = X[y == -1]
ax1.scatter(dogs[:, 0], dogs[:, 1], c='blue', marker='o', s=100, label='Dogs (+1)', edgecolors='black')
ax1.scatter(cats[:, 0], cats[:, 1], c='orange', marker='s', s=100, label='Cats (-1)', edgecolors='black')
ax1.set_xlabel('Whisker Length (X₁)')
ax1.set_ylabel('Ear Flappiness (X₂)')
ax1.set_title('Step 1: Data')
ax1.legend()
ax1.grid(True, alpha=0.3)
ax1.set_xlim(0, 10)
ax1.set_ylim(0, 10)

# Plot 2: H1 - Good separator
ax2 = axes[1]
ax2.scatter(dogs[:, 0], dogs[:, 1], c='blue', marker='o', s=100, label='Dogs (+1)', edgecolors='black')
ax2.scatter(cats[:, 0], cats[:, 1], c='orange', marker='s', s=100, label='Cats (-1)', edgecolors='black')

# Draw H1 line dynamically: θ₁X₁ + θ₂X₂ + θ₀ = 0  →  X₂ = (-θ₁X₁ - θ₀) / θ₂
x_line = np.linspace(0, 10, 100)
theta_0, theta_1, theta_2 = theta_H1
# Calculate y from: θ₁X₁ + θ₂X₂ + θ₀ = 0  →  X₂ = -(θ₁X₁ + θ₀) / θ₂
y_line_H1 = -(theta_1 * x_line + theta_0) / theta_2
# Create equation label
eq_label = f'H1: {theta_1}X₁ + {theta_2}X₂ + {theta_0} = 0'
ax2.plot(x_line, y_line_H1, 'g-', linewidth=2, label=eq_label)
# Clip fill regions to visible area
y_line_H1_clipped = np.clip(y_line_H1, 0, 10)
ax2.fill_between(x_line, y_line_H1_clipped, 10, alpha=0.2, color='blue', label='Dog region')
ax2.fill_between(x_line, 0, y_line_H1_clipped, alpha=0.2, color='orange', label='Cat region')

ax2.set_xlabel('Whisker Length (X₁)')
ax2.set_ylabel('Ear Flappiness (X₂)')
ax2.set_title(f'H1: Loss = {loss_H1} ✅')
ax2.legend(loc='upper left')
ax2.grid(True, alpha=0.3)
ax2.set_xlim(0, 10)
ax2.set_ylim(0, 10)

# Plot 3: H2 - Bad separator
ax3 = axes[2]
ax3.scatter(dogs[:, 0], dogs[:, 1], c='blue', marker='o', s=100, label='Dogs (+1)', edgecolors='black')
ax3.scatter(cats[:, 0], cats[:, 1], c='orange', marker='s', s=100, label='Cats (-1)', edgecolors='black')

# Draw H2 line dynamically: θ₁X₁ + θ₂X₂ + θ₀ = 0  →  X₂ = -(θ₁X₁ + θ₀) / θ₂
theta_0_H2, theta_1_H2, theta_2_H2 = theta_H2
y_line_H2 = -(theta_1_H2 * x_line + theta_0_H2) / theta_2_H2
eq_label_H2 = f'H2: {theta_1_H2}X₁ + {theta_2_H2}X₂ + {theta_0_H2} = 0'
ax3.plot(x_line, y_line_H2, 'r-', linewidth=2, label=eq_label_H2)
y_line_H2_clipped = np.clip(y_line_H2, 0, 10)
ax3.fill_between(x_line, y_line_H2_clipped, 10, alpha=0.2, color='blue', label='Dog region')
ax3.fill_between(x_line, 0, y_line_H2_clipped, alpha=0.2, color='orange', label='Cat region')

# Mark misclassified points
misclassified_mask = predictions_H2 != y
if np.any(misclassified_mask):
    ax3.scatter(X[misclassified_mask, 0], X[misclassified_mask, 1], 
                c='red', marker='x', s=200, linewidths=3, label='Errors')

ax3.set_xlabel('Whisker Length (X₁)')
ax3.set_ylabel('Ear Flappiness (X₂)')
ax3.set_title(f'H2: Loss = {loss_H2} ❌')
ax3.legend(loc='upper left')
ax3.grid(True, alpha=0.3)
ax3.set_xlim(0, 10)
ax3.set_ylim(0, 10)

plt.tight_layout()
plt.savefig('classification_comparison.png', dpi=150, bbox_inches='tight')
print("\n[chart] Visualization saved to 'classification_comparison.png'")
# plt.show()  # Commented to see terminal output

# =========================
# KEY CONCEPTS SUMMARY
# =========================

print("\n" + "=" * 50)
print("KEY TAKEAWAYS")
print("=" * 50)
print("""
1. HYPOTHESIS: A line defined by θ₁X₁ + θ₂X₂ + θ₀ = 0

2. SIGN FUNCTION: 
   - If θ₁X₁ + θ₂X₂ + θ₀ > 0 → Predict +1 (Dog)
   - If θ₁X₁ + θ₂X₂ + θ₀ < 0 → Predict -1 (Cat)

3. LOSS FUNCTION: Count of misclassified points

4. GOAL: Find θ values that minimize loss

5. DECISION BOUNDARY: The line separates the feature space
   into two regions - one for each class
""")
