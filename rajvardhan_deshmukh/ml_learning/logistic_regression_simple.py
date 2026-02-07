"""
Logistic Regression from Scratch with Step-by-Step Visualization
=================================================================
A simple implementation with detailed explanations at each step.
"""

import numpy as np
import matplotlib.pyplot as plt

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

def sigmoid(z):
    """The Sigmoid (Logistic) Function: h(z) = 1 / (1 + e^(-z))"""
    return 1 / (1 + np.exp(-z))


def compute_loss(h, y):
    """Binary Cross-Entropy Loss: J = -1/n * sum[y*log(h) + (1-y)*log(1-h)]"""
    epsilon = 1e-15
    h = np.clip(h, epsilon, 1 - epsilon)
    return (-y * np.log(h) - (1 - y) * np.log(1 - h)).mean()


def compute_gradient(X, y, h):
    """Vectorized Gradient: gradient = (1/n) * X.T @ (h - y)"""
    n = y.shape[0]
    error = h - y
    gradient = np.dot(X.T, error) / n
    return gradient


# =============================================================================
# VISUALIZATION FUNCTIONS
# =============================================================================

def plot_data(X, y, ax=None, title="Data"):
    if ax is None:
        fig, ax = plt.subplots(figsize=(8, 6))
    class_0, class_1 = X[y == 0], X[y == 1]
    ax.scatter(class_0[:, 0], class_0[:, 1], c='blue', marker='o', 
               s=100, label='Dogs (0)', edgecolors='black')
    ax.scatter(class_1[:, 0], class_1[:, 1], c='red', marker='s', 
               s=100, label='Cats (1)', edgecolors='black')
    ax.set_xlabel('Whisker Length (x1)')
    ax.set_ylabel('Ear Flappiness (x2)')
    ax.set_title(title)
    ax.legend()
    ax.grid(True, alpha=0.3)
    return ax


def plot_decision_boundary(X, y, theta, ax=None, title="Decision Boundary"):
    if ax is None:
        fig, ax = plt.subplots(figsize=(8, 6))
    
    x1_min, x1_max = X[:, 0].min() - 1, X[:, 0].max() + 1
    x2_min, x2_max = X[:, 1].min() - 1, X[:, 1].max() + 1
    xx1, xx2 = np.meshgrid(np.linspace(x1_min, x1_max, 200),
                           np.linspace(x2_min, x2_max, 200))
    
    grid = np.c_[xx1.ravel(), xx2.ravel()]
    grid_aug = np.hstack((np.ones((grid.shape[0], 1)), grid))
    probs = sigmoid(np.dot(grid_aug, theta)).reshape(xx1.shape)
    
    contour = ax.contourf(xx1, xx2, probs, levels=np.linspace(0, 1, 11),
                          cmap='RdBu_r', alpha=0.6)
    plt.colorbar(contour, ax=ax, label='P(Cat)')
    ax.contour(xx1, xx2, probs, levels=[0.5], colors='green', linewidths=3)
    
    class_0, class_1 = X[y == 0], X[y == 1]
    ax.scatter(class_0[:, 0], class_0[:, 1], c='blue', marker='o', 
               s=150, label='Dogs (0)', edgecolors='black', linewidths=2)
    ax.scatter(class_1[:, 0], class_1[:, 1], c='red', marker='s', 
               s=150, label='Cats (1)', edgecolors='black', linewidths=2)
    
    ax.set_xlabel('Whisker Length (x1)')
    ax.set_ylabel('Ear Flappiness (x2)')
    ax.set_title(title)
    ax.legend(loc='upper left')
    ax.grid(True, alpha=0.3)
    return ax


def plot_sigmoid():
    fig, ax = plt.subplots(figsize=(8, 5))
    z = np.linspace(-6, 6, 200)
    ax.plot(z, sigmoid(z), 'b-', linewidth=3)
    ax.axhline(y=0.5, color='r', linestyle='--', alpha=0.7, label='Threshold=0.5')
    ax.axvline(x=0, color='gray', linestyle='--', alpha=0.5)
    ax.set_xlabel('z = theta.T @ x')
    ax.set_ylabel('Probability')
    ax.set_title('Sigmoid Function: Converts any z to probability [0,1]')
    ax.legend()
    ax.grid(True, alpha=0.3)
    plt.tight_layout()
    plt.show()


def plot_loss_history(history):
    fig, ax = plt.subplots(figsize=(10, 5))
    ax.plot(history['loss'], 'b-', linewidth=2, marker='o', markersize=3)
    ax.set_xlabel('Iteration')
    ax.set_ylabel('Loss')
    ax.set_title('Loss Convergence: Lower = Better Predictions')
    ax.grid(True, alpha=0.3)
    plt.tight_layout()
    plt.show()


# =============================================================================
# MAIN TRAINING WITH DETAILED EXPLANATIONS
# =============================================================================

def fit_with_explanations(X, y, learning_rate=0.01, iterations=100, plot_every=10):
    """Train with detailed step-by-step explanations."""
    
    print("\n" + "=" * 80)
    print("PHASE 1: DATA PREPARATION - The Augmentation Trick")
    print("=" * 80)
    print("""
WHAT: Adding a column of 1s to our feature matrix X.
WHY:  Our equation is: z = theta_0 + theta_1*x1 + theta_2*x2
      To write this as a single matrix operation (z = X @ theta), we need:
      z = [1, x1, x2] @ [theta_0, theta_1, theta_2]
      The '1' multiplies theta_0, giving us the intercept term.
      
MATHEMATICALLY:
      Original X:       Augmented X:
      [x1, x2]    -->   [1, x1, x2]
      
      This lets us compute ALL predictions in one dot product!
    """)
    
    intercept = np.ones((X.shape[0], 1))
    X_augmented = np.hstack((intercept, X))
    
    print(f"Original X shape: {X.shape} (6 samples, 2 features)")
    print(f"Augmented X shape: {X_augmented.shape} (6 samples, 3 columns: [1, x1, x2])")
    print(f"\nAugmented X:\n{X_augmented}")
    
    # Initialize weights
    print("\n" + "=" * 80)
    print("PHASE 2: WEIGHT INITIALIZATION")
    print("=" * 80)
    print("""
WHAT: Starting with all weights = 0.
WHY:  We need a starting point. Zeros mean "no prior knowledge".
      
THEORETICALLY:
      theta = [0, 0, 0] means:
      - theta_0 = 0: No bias toward either class
      - theta_1 = 0: Whisker length has no influence (yet)
      - theta_2 = 0: Ear flappiness has no influence (yet)
      
      The model will LEARN the correct values through training.
    """)
    
    theta = np.zeros(X_augmented.shape[1])
    print(f"Initial theta: {theta}")
    
    # History tracking
    history = {'loss': [], 'theta': [theta.copy()]}
    
    # Initial state
    print("\n" + "=" * 80)
    print("PHASE 3: INITIAL PREDICTIONS (Before Training)")
    print("=" * 80)
    print("""
STEP 3a: COMPUTE LINEAR SCORES (z = X @ theta)
--------------------------------------------------
WHAT: Multiply features by weights to get a raw score.
WHY:  This score tells us "how strongly" we lean toward Class 1.
      Positive z -> lean toward Cat, Negative z -> lean toward Dog.
    """)
    
    z_init = np.dot(X_augmented, theta)
    print(f"z = X @ theta = X @ [0,0,0] = {z_init}")
    print("RESULT: All zeros! Because theta is all zeros, the model has no opinion yet.")
    
    print("""
STEP 3b: APPLY SIGMOID (h = sigmoid(z))
--------------------------------------------------
WHAT: Convert raw scores to probabilities using sigmoid(z) = 1/(1+e^(-z))
WHY:  We need probabilities (0 to 1), not arbitrary scores.
      
MATHEMATICALLY:
      sigmoid(0) = 1/(1+e^0) = 1/(1+1) = 0.5
    """)
    
    h_init = sigmoid(z_init)
    print(f"h = sigmoid(z) = sigmoid([0,0,0,0,0,0]) = {h_init}")
    print("RESULT: All 0.5! The model is saying 'I have no idea, 50-50 chance for everything'")
    
    print("""
STEP 3c: MEASURE ERROR (Loss = Binary Cross-Entropy)
--------------------------------------------------
WHAT: Calculate how wrong our predictions are.
WHY:  We need a number that tells us "how bad" the model is.
      Lower loss = better predictions.
      
FORMULA: Loss = -mean[y*log(h) + (1-y)*log(1-h)]

THEORETICALLY:
      When h=0.5 and we're doing binary classification:
      Loss = -log(0.5) = log(2) = 0.693
      
      This is MAXIMUM UNCERTAINTY - the model is completely guessing!
    """)
    
    loss_init = compute_loss(h_init, y)
    print(f"Initial Loss = {loss_init:.6f}")
    print(f"This equals ln(2) = {np.log(2):.6f} - Maximum uncertainty!")
    print(f"True labels y: {y}")
    print(f"Predictions h: {h_init}")
    
    # Show initial plot
    fig, ax = plt.subplots(figsize=(8, 6))
    plot_data(X, y, ax, title="Initial State: No Decision Boundary (theta = 0)")
    ax.text(0.02, 0.98, f"theta = {theta}\nLoss = {loss_init:.4f}\nAll predictions = 0.5",
            transform=ax.transAxes, fontsize=10, verticalalignment='top',
            bbox=dict(boxstyle='round', facecolor='wheat', alpha=0.5))
    plt.tight_layout()
    plt.show()
    
    # Training loop
    print("\n" + "=" * 80)
    print("PHASE 4: GRADIENT DESCENT - Learning the Optimal Weights")
    print("=" * 80)
    print(f"""
WHAT: Iteratively adjust weights to minimize loss.
WHY:  We want to find theta values that make the best predictions.

THE ALGORITHM:
      For each iteration:
      1. FORWARD PASS:  Make predictions with current weights
      2. COMPUTE LOSS:  Measure how wrong we are
      3. BACKWARD PASS: Calculate gradient (direction of steepest increase)
      4. UPDATE:        Move weights OPPOSITE to gradient (to decrease loss)
      
FORMULA: theta_new = theta_old - learning_rate * gradient

Learning Rate = {learning_rate} (step size - how big each adjustment is)
Iterations = {iterations} (how many times we repeat this process)
    """)
    
    for i in range(iterations):
        # Forward pass
        z = np.dot(X_augmented, theta)
        h = sigmoid(z)
        
        # Compute loss
        loss = compute_loss(h, y)
        history['loss'].append(loss)
        
        # Compute gradient
        grad = compute_gradient(X_augmented, y, h)
        
        # Update weights
        theta_old = theta.copy()
        theta = theta - (learning_rate * grad)
        history['theta'].append(theta.copy())
        
        # Detailed output at intervals
        if i == 0 or (i + 1) % plot_every == 0 or i == iterations - 1:
            print(f"\n{'=' * 80}")
            print(f"ITERATION {i + 1}")
            print(f"{'=' * 80}")
            
            print(f"""
STEP A - FORWARD PASS (Making Predictions):
-------------------------------------------
z = X @ theta = {z}
h = sigmoid(z) = {h}
(h is the probability of being Class 1 / Cat for each sample)
""")
            
            print(f"""STEP B - COMPUTE ERROR:
-------------------------------------------
error = h - y = {h - y}
(Positive error = predicted too high, Negative = predicted too low)

For Dogs (y=0): We predicted {h[:3]}, wanted 0 -> Error = {(h-y)[:3]}
For Cats (y=1): We predicted {h[3:]}, wanted 1 -> Error = {(h-y)[3:]}

Loss = {loss:.6f}
""")
            
            print(f"""STEP C - BACKWARD PASS (Computing Gradient):
-------------------------------------------
gradient = (1/n) * X.T @ (h - y) = {grad}

INTERPRETATION:
  grad[0] = {grad[0]:.4f} : How much to adjust intercept (theta_0)
  grad[1] = {grad[1]:.4f} : How much whisker length contributes to error
  grad[2] = {grad[2]:.4f} : How much ear flappiness contributes to error
  
Negative gradient -> increase that weight
Positive gradient -> decrease that weight
""")
            
            print(f"""STEP D - UPDATE WEIGHTS:
-------------------------------------------
theta_new = theta_old - learning_rate * gradient
theta_new = {theta_old} - {learning_rate} * {grad}
theta_new = {theta}

WHAT CHANGED:
  theta_0: {theta_old[0]:.4f} -> {theta[0]:.4f} (intercept/bias)
  theta_1: {theta_old[1]:.4f} -> {theta[1]:.4f} (whisker weight)
  theta_2: {theta_old[2]:.4f} -> {theta[2]:.4f} (ear weight)
""")
            
            # Visualization
            fig, ax = plt.subplots(figsize=(10, 7))
            plot_decision_boundary(X, y, theta, ax, 
                                   title=f"Iteration {i+1}: Decision Boundary")
            ax.text(0.02, 0.98, 
                    f"theta = [{theta[0]:.3f}, {theta[1]:.3f}, {theta[2]:.3f}]\n"
                    f"Loss = {loss:.4f}",
                    transform=ax.transAxes, fontsize=10, verticalalignment='top',
                    bbox=dict(boxstyle='round', facecolor='wheat', alpha=0.5))
            plt.tight_layout()
            plt.show()
    
    return theta, history


def predict_proba(X, theta):
    intercept = np.ones((X.shape[0], 1))
    X_augmented = np.hstack((intercept, X))
    return sigmoid(np.dot(X_augmented, theta))


def predict(X, theta, threshold=0.5):
    return (predict_proba(X, theta) >= threshold).astype(int)


# =============================================================================
# MAIN DEMO
# =============================================================================

if __name__ == "__main__":
    print("=" * 80)
    print("LOGISTIC REGRESSION FROM SCRATCH - EDUCATIONAL WALKTHROUGH")
    print("=" * 80)
    print("""
GOAL: Build a classifier to distinguish Dogs from Cats using two features.

THE PROBLEM:
- We have 6 data points (3 dogs, 3 cats)
- Features: Whisker Length (x1) and Ear Flappiness (x2)
- We want to find a LINE (decision boundary) that separates them

THE APPROACH:
1. Start with random weights (all zeros)
2. Make predictions using current weights
3. Measure how wrong we are (loss)
4. Adjust weights to reduce error (gradient descent)
5. Repeat until converged
    """)
    
    # Dataset
    dogs = np.array([[1, 5], [2, 6], [3, 7]])  # Higher ear flappiness
    cats = np.array([[2, 1], [3, 2], [4, 4]])  # Lower ear flappiness
    
    X = np.vstack((dogs, cats))
    y = np.array([0, 0, 0, 1, 1, 1])
    
    print("\n[DATA] Our Dataset:")
    print("  Dogs (Class 0) - Higher ear flappiness:")
    for i, d in enumerate(dogs):
        print(f"    Point {i+1}: Whisker={d[0]}, Ear={d[1]}")
    print("  Cats (Class 1) - Lower ear flappiness:")
    for i, c in enumerate(cats):
        print(f"    Point {i+1}: Whisker={c[0]}, Ear={c[1]}")
    
    # Show sigmoid
    print("\n[THEORY] The Sigmoid Function:")
    print("  Converts any number to probability [0, 1]")
    print("  sigmoid(z) = 1 / (1 + e^(-z))")
    print("  - z = 0    -> 0.5 (uncertain)")
    print("  - z >> 0   -> ~1  (confident Class 1)")
    print("  - z << 0   -> ~0  (confident Class 0)")
    plot_sigmoid()
    
    # Initial data
    print("\n[VISUAL] Plotting raw data...")
    fig, ax = plt.subplots(figsize=(8, 6))
    plot_data(X, y, ax, title="Raw Data: Dogs vs Cats")
    plt.tight_layout()
    plt.show()
    
    # Training
    print("\n" + "=" * 80)
    print("STARTING TRAINING...")
    print("=" * 80)
    
    theta, history = fit_with_explanations(
        X, y, 
        learning_rate=0.1, 
        iterations=50, 
        plot_every=10
    )
    
    # Results
    print("\n" + "=" * 80)
    print("PHASE 5: FINAL RESULTS")
    print("=" * 80)
    print(f"""
TRAINED WEIGHTS:
  theta_0 (intercept) = {theta[0]:.4f}
    -> Baseline bias. Positive = slight lean toward Cat.
    
  theta_1 (whisker)   = {theta[1]:.4f}
    -> POSITIVE: Higher whisker length -> More likely Cat
    
  theta_2 (ear)       = {theta[2]:.4f}
    -> NEGATIVE: Higher ear flappiness -> More likely Dog

DECISION BOUNDARY EQUATION:
  {theta[0]:.3f} + {theta[1]:.3f}*x1 + {theta[2]:.3f}*x2 = 0
  
  Points where this equals 0 form the green decision line.
  Above the line: Dog region (probability < 0.5)
  Below the line: Cat region (probability > 0.5)
    """)
    
    # Loss history
    print("[VISUAL] Loss convergence over training...")
    plot_loss_history(history)
    
    # Predictions
    print("\n[PREDICTIONS] Testing on training data:")
    print("-" * 60)
    predictions = predict(X, theta)
    probabilities = predict_proba(X, theta)
    
    for feat, true, pred, prob in zip(X, y, predictions, probabilities):
        label = "Dog" if true == 0 else "Cat"
        pred_label = "Dog" if pred == 0 else "Cat"
        status = "[CORRECT]" if true == pred else "[WRONG]"
        print(f"  Point {feat} | True: {label} | Pred: {pred_label} | P(Cat)={prob:.3f} {status}")
    
    accuracy = (predictions == y).mean() * 100
    print(f"\nACCURACY: {accuracy:.1f}%")
    
    # Final visualization
    print("\n[VISUAL] Final decision boundary...")
    fig, ax = plt.subplots(figsize=(10, 7))
    plot_decision_boundary(X, y, theta, ax, title="Final Trained Model")
    plt.tight_layout()
    plt.show()
    
    print("\n" + "=" * 80)
    print("COMPLETE! You've built logistic regression from scratch.")
    print("=" * 80)
