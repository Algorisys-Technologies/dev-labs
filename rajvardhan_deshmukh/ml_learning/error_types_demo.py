# =========================
# TRAINING, TESTING & CROSS-VALIDATION ERRORS
# =========================
# A complete guide to understanding model evaluation
# Using the Cats vs Dogs classification problem

import numpy as np
import matplotlib.pyplot as plt

# =========================
# THEORETICAL BACKGROUND
# =========================
"""
When building a machine learning model, we need to answer:
"How well will this model work on NEW, UNSEEN data?"

We use three types of errors to understand this:

1. TRAINING ERROR (E_train)
   - Error on the data we used to "train" (or fit) our model
   - Problem: Can be misleadingly low (model memorizes data)
   
2. TEST ERROR (E_test)  
   - Error on data the model has NEVER seen
   - Better estimate of real-world performance
   - Problem: Wastes data (some data only used for testing)

3. CROSS-VALIDATION ERROR (E_cv)
   - Average error across multiple train/test splits
   - Uses ALL data for both training AND testing (just not at same time)
   - Best estimate of real-world performance
"""

print("=" * 70)
print("TRAINING, TESTING & CROSS-VALIDATION ERRORS - EXPLAINED")
print("=" * 70)

# =========================
# STEP 1: CREATE OUR DATA
# =========================

# Dogs (+1): Short whiskers, high ear flappiness
# Cats (-1): Long whiskers, low ear flappiness
data = np.array([
    # Dogs (+1)
    [2.0, 8.0, +1],  # Point 0
    [2.5, 7.5, +1],  # Point 1
    [3.0, 8.5, +1],  # Point 2
    [1.5, 9.0, +1],  # Point 3
    [2.8, 7.0, +1],  # Point 4
    [3.2, 8.2, +1],  # Point 5
    [2.2, 7.8, +1],  # Point 6
    [1.8, 8.8, +1],  # Point 7
    [2.6, 7.2, +1],  # Point 8
    [3.5, 7.5, +1],  # Point 9
    
    # Cats (-1)
    [7.0, 2.0, -1],  # Point 10
    [6.5, 2.5, -1],  # Point 11
    [8.0, 1.5, -1],  # Point 12
    [7.5, 3.0, -1],  # Point 13
    [6.8, 2.2, -1],  # Point 14
    [7.2, 1.8, -1],  # Point 15
    [8.5, 2.8, -1],  # Point 16
    [6.0, 3.5, -1],  # Point 17
    [7.8, 2.0, -1],  # Point 18
    [6.2, 3.2, -1],  # Point 19
])

X = data[:, :2]
y = data[:, 2]

print(f"\nTotal data points: {len(y)} (10 dogs, 10 cats)")

# =========================
# STEP 2: DEFINE HELPER FUNCTIONS
# =========================

def hypothesis(X, theta):
    """Predict using linear classifier: sign(θ₁X₁ + θ₂X₂ + θ₀)"""
    theta_0, theta_1, theta_2 = theta
    linear_output = theta_1 * X[:, 0] + theta_2 * X[:, 1] + theta_0
    return np.sign(linear_output)

def calculate_error(y_true, y_pred):
    """Calculate error as fraction of mistakes (0 to 1)"""
    return np.mean(y_true != y_pred)

def calculate_loss(y_true, y_pred):
    """Calculate loss as count of mistakes"""
    return np.sum(y_true != y_pred)

# Our hypothesis: a diagonal line that should work well
theta = [1, -1, 1]  # Equation: -X₁ + X₂ + 1 = 0  →  X₂ = X₁ - 1

print(f"\nHypothesis: θ = {theta}")
print(f"Equation: -1·X₁ + 1·X₂ + 1 = 0  →  X₂ = X₁ - 1")

# =========================
# PART 1: TRAINING ERROR
# =========================
print("\n" + "=" * 70)
print("PART 1: TRAINING ERROR")
print("=" * 70)

print("""
CONCEPT:
--------
Training error measures how well our model fits the data it was trained on.

    E_train = (# mistakes on training data) / (# training samples)

PROBLEM: Training error can be DECEPTIVELY LOW!
- A model can "memorize" the training data perfectly
- But fail completely on new data (this is called OVERFITTING)

ANALOGY: 
- Like a student who memorizes exam answers without understanding
- They ace the practice test but fail the real exam
""")

# Calculate training error on ALL data
train_predictions = hypothesis(X, theta)
train_error = calculate_error(y, train_predictions)
train_loss = calculate_loss(y, train_predictions)

print(f"Training on ALL 20 points:")
print(f"  Predictions: {train_predictions.astype(int)}")
print(f"  Actual:      {y.astype(int)}")
print(f"  Mistakes:    {train_loss}")
print(f"  Training Error: {train_error:.2%}")

# =========================
# PART 2: TRAIN/TEST SPLIT
# =========================
print("\n" + "=" * 70)
print("PART 2: TEST ERROR (Train/Test Split)")
print("=" * 70)

print("""
CONCEPT:
--------
Split data into two parts:
  - TRAINING SET: Used to fit/select the model
  - TEST SET: Used ONLY for final evaluation (never seen during training)

    E_test = (# mistakes on test data) / (# test samples)

ADVANTAGE: Gives honest estimate of real-world performance
PROBLEM: We "waste" some data that could help training

COMMON SPLITS: 80/20, 70/30, or 60/40
""")

# Split: First 8 dogs + 8 cats for training, last 2 of each for testing
train_indices = list(range(0, 8)) + list(range(10, 18))  # 16 points
test_indices = list(range(8, 10)) + list(range(18, 20))   # 4 points

X_train, y_train = X[train_indices], y[train_indices]
X_test, y_test = X[test_indices], y[test_indices]

print(f"Split: 80% train (16 points), 20% test (4 points)")
print(f"\nTraining set indices: {train_indices}")
print(f"Test set indices: {test_indices}")

# Calculate training error
train_pred = hypothesis(X_train, theta)
train_error = calculate_error(y_train, train_pred)
train_loss = calculate_loss(y_train, train_pred)

print(f"\n--- Training Set Performance ---")
print(f"  Training predictions: {train_pred.astype(int)}")
print(f"  Training actual:      {y_train.astype(int)}")
print(f"  Training mistakes:    {train_loss}")
print(f"  Training Error:       {train_error:.2%}")

# Calculate test error
test_pred = hypothesis(X_test, theta)
test_error = calculate_error(y_test, test_pred)
test_loss = calculate_loss(y_test, test_pred)

print(f"\n--- Test Set Performance ---")
print(f"  Test points: {X_test}")
print(f"  Test predictions: {test_pred.astype(int)}")
print(f"  Test actual:      {y_test.astype(int)}")
print(f"  Test mistakes:    {test_loss}")
print(f"  Test Error:       {test_error:.2%}")

print(f"\n>>> COMPARISON: Train Error = {train_error:.2%}, Test Error = {test_error:.2%}")

# =========================
# PART 3: K-FOLD CROSS-VALIDATION
# =========================
print("\n" + "=" * 70)
print("PART 3: K-FOLD CROSS-VALIDATION")
print("=" * 70)

print("""
CONCEPT:
--------
Problem with single train/test split:
  - Result depends on WHICH points end up in test set
  - Some splits might be "lucky" or "unlucky"

Solution: K-FOLD CROSS-VALIDATION
  1. Split data into K equal parts (called "folds")
  2. For each fold:
     - Use that fold as test set
     - Use remaining K-1 folds as training set
     - Calculate test error
  3. Average all K test errors → Cross-Validation Error

EXAMPLE WITH K=5:
  Fold 1: [TEST][train][train][train][train] → Error₁
  Fold 2: [train][TEST][train][train][train] → Error₂
  Fold 3: [train][train][TEST][train][train] → Error₃
  Fold 4: [train][train][train][TEST][train] → Error₄
  Fold 5: [train][train][train][train][TEST] → Error₅
  
  E_cv = (Error₁ + Error₂ + Error₃ + Error₄ + Error₅) / 5

ADVANTAGE: Every point gets tested exactly once!
           Uses all data efficiently.
""")

def k_fold_cross_validation(X, y, theta, k=5, verbose=True):
    """
    Perform k-fold cross-validation.
    
    Args:
        X: Feature data
        y: Labels
        theta: Model parameters
        k: Number of folds
        verbose: Print details
    
    Returns:
        Average cross-validation error
    """
    n = len(y)
    fold_size = n // k
    errors = []
    
    if verbose:
        print(f"\nPerforming {k}-fold cross-validation on {n} samples...")
        print(f"Each fold has {fold_size} samples\n")
    
    for fold in range(k):
        # Determine test indices for this fold
        test_start = fold * fold_size
        test_end = test_start + fold_size
        test_idx = list(range(test_start, test_end))
        train_idx = [i for i in range(n) if i not in test_idx]
        
        # Split data
        X_train_fold = X[train_idx]
        y_train_fold = y[train_idx]
        X_test_fold = X[test_idx]
        y_test_fold = y[test_idx]
        
        # Calculate error on this fold's test set
        predictions = hypothesis(X_test_fold, theta)
        fold_error = calculate_error(y_test_fold, predictions)
        fold_loss = calculate_loss(y_test_fold, predictions)
        errors.append(fold_error)
        
        if verbose:
            print(f"Fold {fold + 1}:")
            print(f"  Train indices: {train_idx}")
            print(f"  Test indices:  {test_idx}")
            print(f"  Test predictions: {predictions.astype(int)}")
            print(f"  Test actual:      {y_test_fold.astype(int)}")
            print(f"  Fold Error:       {fold_error:.2%} ({fold_loss}/{fold_size} mistakes)")
            print()
    
    cv_error = np.mean(errors)
    
    if verbose:
        print("-" * 50)
        print(f"Individual fold errors: {[f'{e:.2%}' for e in errors]}")
        print(f"CROSS-VALIDATION ERROR (average): {cv_error:.2%}")
    
    return cv_error

# Run 5-fold cross-validation
cv_error = k_fold_cross_validation(X, y, theta, k=5, verbose=True)

# =========================
# SUMMARY
# =========================
print("\n" + "=" * 70)
print("SUMMARY: ALL ERROR TYPES COMPARED")
print("=" * 70)

# Recalculate all errors
all_predictions = hypothesis(X, theta)
overall_train_error = calculate_error(y, all_predictions)

print(f"""
+----------------------+----------+----------------------------------------+
| Error Type           | Value    | What it tells us                       |
+----------------------+----------+----------------------------------------+
| Training Error       | {overall_train_error:>6.2%}  | How well model fits training data      |
| Test Error (80/20)   | {test_error:>6.2%}  | Performance on held-out data           |
| Cross-Val Error (5F) | {cv_error:>6.2%}  | Robust estimate using all data         |
+----------------------+----------+----------------------------------------+

KEY INSIGHTS:
-------------
1. Training Error can be ZERO even for bad models (overfitting)
2. Test Error depends on which data goes in test set
3. Cross-Validation Error is most reliable - averages over all splits

WHEN TO USE WHAT:
-----------------
- Training Error: Quick check during development
- Test Error: Final evaluation with large datasets  
- Cross-Validation: When data is limited, need reliable estimate

THE RELATIONSHIP:
-----------------
Usually: E_train ≤ E_cv ≤ E_test (on new unseen data)

If E_train << E_test: Model is OVERFITTING (memorizing, not learning)
If E_train ≈ E_test:  Model is generalizing well!
""")

# =========================
# VISUALIZATION
# =========================
print("\n" + "=" * 70)
print("VISUALIZATION")
print("=" * 70)

fig, axes = plt.subplots(1, 3, figsize=(15, 5))

# Colors for folds
fold_colors = ['red', 'green', 'blue', 'purple', 'orange']

# Plot 1: Train/Test Split
ax1 = axes[0]
ax1.scatter(X_train[:, 0], X_train[:, 1], c='blue', marker='o', s=100, 
            label='Training', edgecolors='black', alpha=0.7)
ax1.scatter(X_test[:, 0], X_test[:, 1], c='red', marker='s', s=150, 
            label='Test', edgecolors='black', linewidths=2)
ax1.set_xlabel('Whisker Length (X1)')
ax1.set_ylabel('Ear Flappiness (X2)')
ax1.set_title('Train/Test Split (80/20)')
ax1.legend()
ax1.grid(True, alpha=0.3)
ax1.set_xlim(0, 10)
ax1.set_ylim(0, 10)

# Plot 2: K-Fold visualization (show which points are in which fold)
ax2 = axes[1]
n = len(y)
k = 5
fold_size = n // k
for fold in range(k):
    test_start = fold * fold_size
    test_end = test_start + fold_size
    fold_points = X[test_start:test_end]
    ax2.scatter(fold_points[:, 0], fold_points[:, 1], 
                c=fold_colors[fold], marker='o', s=100, 
                label=f'Fold {fold+1}', edgecolors='black')
ax2.set_xlabel('Whisker Length (X1)')
ax2.set_ylabel('Ear Flappiness (X2)')
ax2.set_title('5-Fold Split (each color = 1 fold)')
ax2.legend()
ax2.grid(True, alpha=0.3)
ax2.set_xlim(0, 10)
ax2.set_ylim(0, 10)

# Plot 3: Error comparison bar chart
ax3 = axes[2]
errors = [overall_train_error * 100, test_error * 100, cv_error * 100]
labels = ['Training\nError', 'Test\nError', 'Cross-Val\nError']
colors = ['green', 'orange', 'blue']
bars = ax3.bar(labels, errors, color=colors, edgecolor='black', linewidth=2)
ax3.set_ylabel('Error (%)')
ax3.set_title('Error Comparison')
ax3.set_ylim(0, max(errors) * 1.5 + 5)
# Add value labels on bars
for bar, error in zip(bars, errors):
    ax3.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 1, 
             f'{error:.1f}%', ha='center', va='bottom', fontweight='bold')

plt.tight_layout()
plt.savefig('error_types_comparison.png', dpi=150, bbox_inches='tight')
print("\nVisualization saved to 'error_types_comparison.png'")

print("\n" + "=" * 70)
print("END OF TUTORIAL")
print("=" * 70)
