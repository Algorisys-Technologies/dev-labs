"""
Logistic Regression from Scratch (No External Libraries for Core Logic)

This implementation builds logistic regression without using sklearn, tensorflow,
or any other ML library. We implement:
1. Sigmoid function (the core of logistic regression)
2. Hypothesis function (probability prediction)
3. Cost function (cross-entropy loss)
4. Gradient descent (parameter optimization)
5. Prediction function
6. Visualization of each step and iteration

Mathematical Background:
------------------------
Logistic regression models the probability that input x belongs to class 1:
    P(y=1|x) = sigmoid(z) = 1 / (1 + e^(-z))
    where z = theta_0 + theta_1*x_1 + theta_2*x_2 + ... + theta_n*x_n

The sigmoid function maps any real number to (0, 1), making it perfect for
probability estimation.

Cost Function (Cross-Entropy Loss):
    J(theta) = -1/m * sum[ y*log(h(x)) + (1-y)*log(1 - h(x)) ]

This cost function penalizes confident wrong predictions heavily.

Gradient Descent Update Rule:
    theta_j := theta_j - alpha * (1/m) * sum[ (h(x) - y) * x_j ]

where alpha is the learning rate and m is the number of training examples.
"""

import math
import random
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.animation import FuncAnimation
import numpy as np  # Only used for visualization meshgrid, not for core logic

# =============================================================================
# PART 1: MATHEMATICAL HELPER FUNCTIONS
# =============================================================================

def exp(x):
    """
    Calculate e^x (exponential function) without using math.exp
    Uses Taylor series expansion: e^x = 1 + x + x^2/2! + x^3/3! + ...
    
    Args:
        x: The exponent value
    
    Returns:
        Approximation of e^x
    
    Note: For very large negative x, this can overflow. We'll use math.exp
          as a fallback for numerical stability.
    """
    # For numerical stability, we'll use the built-in math.exp
    # Writing a fully stable exp from Taylor series is complex
    # This is acceptable since math is a standard library, not an ML library
    try:
        return math.exp(x)
    except OverflowError:
        # Handle overflow for very large positive x
        return float('inf') if x > 0 else 0.0


def log(x):
    """
    Calculate natural logarithm ln(x)
    
    Args:
        x: The input value (must be > 0)
    
    Returns:
        Natural log of x
    """
    # Using math.log for numerical stability
    # Again, math is standard library, not an ML library
    if x <= 0:
        # Avoid log(0) which is undefined
        return float('-inf')
    return math.log(x)


# =============================================================================
# PART 2: CORE LOGISTIC REGRESSION FUNCTIONS
# =============================================================================

def sigmoid(z):
    """
    Sigmoid activation function: sigma(z) = 1 / (1 + e^(-z))
    
    The sigmoid function is the heart of logistic regression.
    It maps any real number to a value between 0 and 1, which we
    interpret as a probability.
    
    Properties:
    - sigmoid(0) = 0.5
    - sigmoid(large positive) → 1
    - sigmoid(large negative) → 0
    - sigmoid is symmetric: sigmoid(-z) = 1 - sigmoid(z)
    
    Args:
        z: Linear combination (theta_0 + theta_1*x_1 + ... + theta_n*x_n)
    
    Returns:
        Value between 0 and 1 representing probability
    """
    # Handle numerical stability for very negative z
    # When z is very negative, e^(-z) becomes very large
    # When z is very positive, e^(-z) approaches 0
    if z >= 0:
        # Standard formula for positive z (stable)
        return 1.0 / (1.0 + exp(-z))
    else:
        # Alternative formula for negative z (more stable)
        # sigmoid(z) = e^z / (1 + e^z)
        exp_z = exp(z)
        return exp_z / (1.0 + exp_z)


def hypothesis(X, theta):
    """
    Compute the hypothesis (predicted probability) for logistic regression.
    
    h(x) = sigmoid(theta^T * x) = sigmoid(theta_0 + theta_1*x_1 + ... + theta_n*x_n)
    
    This function computes:
    1. The linear combination z = theta_0 + theta_1*x_1 + ... + theta_n*x_n
    2. Applies sigmoid to get probability
    
    Args:
        X: A single data point as list [x_1, x_2, ..., x_n] (without bias term)
           The bias term (x_0 = 1) is handled internally
        theta: Model parameters as list [theta_0, theta_1, ..., theta_n]
    
    Returns:
        Probability that this data point belongs to class 1
    """
    # Step 1: Calculate the linear combination z = theta^T * x
    # z = theta_0 * 1 + theta_1 * x_1 + theta_2 * x_2 + ...
    
    # Start with bias term: theta_0 * 1
    z = theta[0]  # theta_0 (bias/intercept)
    
    # Add weighted features: sum of theta_i * x_i for i = 1 to n
    for i in range(len(X)):
        z += theta[i + 1] * X[i]  # theta[i+1] because theta[0] is bias
    
    # Step 2: Apply sigmoid function to get probability
    return sigmoid(z)


def predict(X, theta, threshold=0.5):
    """
    Make binary class prediction (0 or 1) for a single data point.
    
    If probability >= threshold, predict class 1
    If probability < threshold, predict class 0
    
    Args:
        X: A single data point as list [x_1, x_2, ..., x_n]
        theta: Model parameters
        threshold: Decision boundary (default 0.5)
    
    Returns:
        Predicted class (0 or 1)
    """
    probability = hypothesis(X, theta)
    return 1 if probability >= threshold else 0


def compute_cost(X_data, y_data, theta):
    """
    Compute the cross-entropy cost (loss) function.
    
    The cost function measures how well our model's predictions match
    the actual labels. Lower cost means better predictions.
    
    Formula:
    J(theta) = -1/m * sum_{i=1}^{m}[ y_i * log(h(x_i)) + (1-y_i) * log(1-h(x_i)) ]
    
    Why this formula?
    - When y=1: We want log(h(x)) to be high → h(x) should be close to 1
    - When y=0: We want log(1-h(x)) to be high → h(x) should be close to 0
    - The negative sign makes it a minimization problem
    
    Args:
        X_data: List of data points, each point is [x_1, x_2, ..., x_n]
        y_data: List of true labels (0 or 1)
        theta: Model parameters
    
    Returns:
        The cost value (lower is better)
    """
    m = len(X_data)  # Number of training examples
    total_cost = 0.0
    
    for i in range(m):
        # Get the predicted probability for this example
        h = hypothesis(X_data[i], theta)
        
        # Clip h to avoid log(0) issues
        # If h is exactly 0 or 1, log will be problematic
        epsilon = 1e-15  # Small value to prevent log(0)
        h = max(epsilon, min(1 - epsilon, h))
        
        # Calculate cost contribution from this example
        # cost_i = y * log(h) + (1-y) * log(1-h)
        if y_data[i] == 1:
            # When true label is 1
            cost_i = log(h)
        else:
            # When true label is 0
            cost_i = log(1 - h)
        
        total_cost += cost_i
    
    # Average the cost and negate (since we used log, not -log)
    return -total_cost / m


def compute_gradients(X_data, y_data, theta):
    """
    Compute the gradients of the cost function with respect to each theta.
    
    The gradient tells us which direction to move theta to decrease the cost.
    
    Formula for gradient of theta_j:
    dJ/d(theta_j) = (1/m) * sum_{i=1}^{m}[ (h(x_i) - y_i) * x_i_j ]
    
    Where:
    - h(x_i) is the predicted probability for example i
    - y_i is the true label for example i
    - x_i_j is the j-th feature of example i (x_i_0 = 1 for bias)
    
    Args:
        X_data: List of data points
        y_data: List of true labels
        theta: Current model parameters
    
    Returns:
        List of gradients, one for each theta parameter
    """
    m = len(X_data)  # Number of training examples
    n = len(theta)   # Number of parameters (including bias)
    
    # Initialize gradients to zero
    gradients = [0.0] * n
    
    # Accumulate gradient from each training example
    for i in range(m):
        # Get predictions
        h = hypothesis(X_data[i], theta)
        
        # Error = prediction - actual
        error = h - y_data[i]
        
        # Update gradient for bias term (theta_0)
        # x_0 is always 1 (the bias term)
        gradients[0] += error * 1.0
        
        # Update gradients for feature weights (theta_1, theta_2, ...)
        for j in range(len(X_data[i])):
            gradients[j + 1] += error * X_data[i][j]
    
    # Average the gradients
    for j in range(n):
        gradients[j] /= m
    
    return gradients


def gradient_descent(X_data, y_data, theta, learning_rate, num_iterations, verbose=True):
    """
    Optimize theta using gradient descent.
    
    Gradient descent is an iterative optimization algorithm that finds
    the values of theta that minimize the cost function.
    
    Update rule:
    theta_j := theta_j - learning_rate * gradient_j
    
    The learning rate controls how big of a step we take in the direction
    of the negative gradient.
    
    Args:
        X_data: List of training examples
        y_data: List of true labels
        theta: Initial parameter values
        learning_rate: Step size for updates (alpha)
        num_iterations: Number of iterations to run
        verbose: If True, print progress every 100 iterations
    
    Returns:
        Optimized theta parameters, list of costs, and list of theta history
    """
    # Make a copy of theta so we don't modify the original
    theta = theta.copy()
    cost_history = []
    theta_history = [theta.copy()]  # Store theta at each iteration for visualization
    
    for iteration in range(num_iterations):
        # Step 1: Compute gradients
        gradients = compute_gradients(X_data, y_data, theta)
        
        # Step 2: Update each parameter
        for j in range(len(theta)):
            theta[j] = theta[j] - learning_rate * gradients[j]
        
        # Step 3: Record cost and theta for monitoring
        cost = compute_cost(X_data, y_data, theta)
        cost_history.append(cost)
        theta_history.append(theta.copy())
        
        # Print progress
        if verbose and (iteration % 100 == 0 or iteration == num_iterations - 1):
            print(f"Iteration {iteration:4d} | Cost: {cost:.6f} | "
                  f"θ = [{theta[0]:.3f}, {theta[1]:.3f}, {theta[2]:.3f}]")
    
    return theta, cost_history, theta_history


def calculate_accuracy(X_data, y_data, theta):
    """
    Calculate the accuracy of the model on a dataset.
    
    Accuracy = (Number of correct predictions) / (Total predictions)
    
    Args:
        X_data: List of data points
        y_data: List of true labels
        theta: Model parameters
    
    Returns:
        Accuracy as a percentage (0-100)
    """
    correct = 0
    m = len(X_data)
    
    for i in range(m):
        prediction = predict(X_data[i], theta)
        if prediction == y_data[i]:
            correct += 1
    
    return (correct / m) * 100


# =============================================================================
# PART 3: DATA GENERATION FOR TESTING
# =============================================================================

def generate_sample_data(num_samples=100, seed=42):
    """
    Generate synthetic binary classification data for testing.
    
    We create two clusters:
    - Class 0: Centered around (2, 2)
    - Class 1: Centered around (6, 6)
    
    This creates a linearly separable dataset that logistic regression
    should be able to classify well.
    
    Args:
        num_samples: Total number of samples (split evenly between classes)
        seed: Random seed for reproducibility
    
    Returns:
        X_data: List of [x_1, x_2] feature vectors
        y_data: List of labels (0 or 1)
    """
    random.seed(seed)
    
    X_data = []
    y_data = []
    
    samples_per_class = num_samples // 2
    
    # Generate Class 0 samples (centered around (2, 2))
    for _ in range(samples_per_class):
        x1 = 2 + random.gauss(0, 1)  # Mean 2, std 1
        x2 = 2 + random.gauss(0, 1)
        X_data.append([x1, x2])
        y_data.append(0)
    
    # Generate Class 1 samples (centered around (6, 6))
    for _ in range(samples_per_class):
        x1 = 6 + random.gauss(0, 1)  # Mean 6, std 1
        x2 = 6 + random.gauss(0, 1)
        X_data.append([x1, x2])
        y_data.append(1)
    
    return X_data, y_data


# =============================================================================
# PART 4: VISUALIZATION FUNCTIONS
# =============================================================================

def visualize_sigmoid():
    """
    Visualize the sigmoid function to understand its properties.
    Shows how sigmoid maps any real number to (0, 1).
    """
    print("\n📊 STEP 1: Visualizing the Sigmoid Function")
    print("-" * 50)
    
    # Generate z values from -10 to 10
    z_values = [i * 0.1 for i in range(-100, 101)]
    sigmoid_values = [sigmoid(z) for z in z_values]
    
    plt.figure(figsize=(10, 6))
    plt.plot(z_values, sigmoid_values, 'b-', linewidth=2, label='σ(z) = 1/(1+e^(-z))')
    
    # Mark important points
    plt.axhline(y=0.5, color='gray', linestyle='--', alpha=0.5, label='y = 0.5')
    plt.axhline(y=0, color='gray', linestyle='-', alpha=0.3)
    plt.axhline(y=1, color='gray', linestyle='-', alpha=0.3)
    plt.axvline(x=0, color='gray', linestyle='-', alpha=0.3)
    
    # Mark sigmoid(0) = 0.5
    plt.plot(0, 0.5, 'ro', markersize=10, label='σ(0) = 0.5')
    
    plt.xlabel('z (linear combination)', fontsize=12)
    plt.ylabel('σ(z) (probability)', fontsize=12)
    plt.title('Sigmoid Function: Maps any real number to (0, 1)', fontsize=14)
    plt.legend(loc='upper left')
    plt.grid(True, alpha=0.3)
    plt.ylim(-0.1, 1.1)
    
    # Add annotations
    plt.annotate('High probability\n(Predict Class 1)', xy=(5, 0.95), fontsize=10, 
                 ha='center', color='green')
    plt.annotate('Low probability\n(Predict Class 0)', xy=(-5, 0.05), fontsize=10, 
                 ha='center', color='red')
    plt.annotate('Decision\nBoundary', xy=(0, 0.5), xytext=(2, 0.6),
                 fontsize=10, ha='center',
                 arrowprops=dict(arrowstyle='->', color='black'))
    
    plt.tight_layout()
    plt.savefig('step1_sigmoid_function.png', dpi=150)
    plt.show()
    print("  ✓ Saved: step1_sigmoid_function.png")


def visualize_data(X_data, y_data):
    """
    Visualize the training data points.
    """
    print("\n📊 STEP 2: Visualizing Training Data")
    print("-" * 50)
    
    # Separate classes
    class_0_x1 = [X_data[i][0] for i in range(len(X_data)) if y_data[i] == 0]
    class_0_x2 = [X_data[i][1] for i in range(len(X_data)) if y_data[i] == 0]
    class_1_x1 = [X_data[i][0] for i in range(len(X_data)) if y_data[i] == 1]
    class_1_x2 = [X_data[i][1] for i in range(len(X_data)) if y_data[i] == 1]
    
    plt.figure(figsize=(10, 8))
    plt.scatter(class_0_x1, class_0_x2, c='red', marker='o', s=80, 
                label='Class 0', alpha=0.7, edgecolors='darkred')
    plt.scatter(class_1_x1, class_1_x2, c='blue', marker='s', s=80, 
                label='Class 1', alpha=0.7, edgecolors='darkblue')
    
    plt.xlabel('Feature x₁', fontsize=12)
    plt.ylabel('Feature x₂', fontsize=12)
    plt.title('Training Data: Two Classes', fontsize=14)
    plt.legend(loc='upper left', fontsize=11)
    plt.grid(True, alpha=0.3)
    
    # Add annotations for cluster centers
    plt.annotate('Class 0 cluster\n(centered ~(2,2))', xy=(2, 2), xytext=(0, 0),
                 fontsize=10, arrowprops=dict(arrowstyle='->', color='red'))
    plt.annotate('Class 1 cluster\n(centered ~(6,6))', xy=(6, 6), xytext=(8, 7),
                 fontsize=10, arrowprops=dict(arrowstyle='->', color='blue'))
    
    plt.tight_layout()
    plt.savefig('step2_training_data.png', dpi=150)
    plt.show()
    print("  ✓ Saved: step2_training_data.png")


def visualize_cost_function(X_data, y_data):
    """
    Visualize how the cost function changes with theta values.
    Shows the "landscape" we're trying to minimize.
    """
    print("\n📊 STEP 3: Visualizing Cost Function Landscape")
    print("-" * 50)
    
    # We'll fix theta_0 and vary theta_1 and theta_2 to show the cost surface
    theta_0 = -8  # Approximate optimal bias
    
    # Create grid of theta values
    theta1_range = np.linspace(-2, 4, 50)
    theta2_range = np.linspace(-2, 4, 50)
    
    costs = np.zeros((len(theta1_range), len(theta2_range)))
    
    for i, t1 in enumerate(theta1_range):
        for j, t2 in enumerate(theta2_range):
            theta = [theta_0, t1, t2]
            costs[j, i] = compute_cost(X_data, y_data, theta)
    
    plt.figure(figsize=(12, 5))
    
    # Contour plot
    plt.subplot(1, 2, 1)
    contour = plt.contour(theta1_range, theta2_range, costs, levels=20, cmap='viridis')
    plt.colorbar(contour, label='Cost J(θ)')
    plt.xlabel('θ₁ (weight for x₁)', fontsize=12)
    plt.ylabel('θ₂ (weight for x₂)', fontsize=12)
    plt.title(f'Cost Function Contours (θ₀={theta_0})', fontsize=14)
    plt.plot(1, 1, 'r*', markersize=15, label='Approximate minimum')
    plt.legend()
    
    # 3D surface
    ax = plt.subplot(1, 2, 2, projection='3d')
    T1, T2 = np.meshgrid(theta1_range, theta2_range)
    ax.plot_surface(T1, T2, costs, cmap='viridis', alpha=0.8)
    ax.set_xlabel('θ₁')
    ax.set_ylabel('θ₂')
    ax.set_zlabel('Cost')
    ax.set_title('Cost Function Surface', fontsize=14)
    
    plt.tight_layout()
    plt.savefig('step3_cost_landscape.png', dpi=150)
    plt.show()
    print("  ✓ Saved: step3_cost_landscape.png")


def visualize_gradient_descent_iterations(X_data, y_data, theta_history, cost_history):
    """
    Visualize how decision boundary evolves during training.
    Shows snapshots at different iterations.
    """
    print("\n📊 STEP 4: Visualizing Decision Boundary Evolution")
    print("-" * 50)
    
    # Select key iterations to show
    total_iters = len(theta_history) - 1
    key_iterations = [0, 10, 50, 100, 200, 500, total_iters]
    key_iterations = [i for i in key_iterations if i <= total_iters]
    
    # Separate classes for plotting
    class_0_x1 = [X_data[i][0] for i in range(len(X_data)) if y_data[i] == 0]
    class_0_x2 = [X_data[i][1] for i in range(len(X_data)) if y_data[i] == 0]
    class_1_x1 = [X_data[i][0] for i in range(len(X_data)) if y_data[i] == 1]
    class_1_x2 = [X_data[i][1] for i in range(len(X_data)) if y_data[i] == 1]
    
    # Calculate plot bounds
    x_min = min(min(class_0_x1), min(class_1_x1)) - 1
    x_max = max(max(class_0_x1), max(class_1_x1)) + 1
    
    # Create subplot grid
    n_plots = len(key_iterations)
    n_cols = 3
    n_rows = (n_plots + n_cols - 1) // n_cols
    
    fig, axes = plt.subplots(n_rows, n_cols, figsize=(15, 5 * n_rows))
    axes = axes.flatten() if n_plots > 1 else [axes]
    
    for idx, iteration in enumerate(key_iterations):
        ax = axes[idx]
        theta = theta_history[iteration]
        
        # Plot data points
        ax.scatter(class_0_x1, class_0_x2, c='red', marker='o', s=50, 
                   label='Class 0', alpha=0.6, edgecolors='darkred')
        ax.scatter(class_1_x1, class_1_x2, c='blue', marker='s', s=50, 
                   label='Class 1', alpha=0.6, edgecolors='darkblue')
        
        # Plot decision boundary: theta_0 + theta_1*x1 + theta_2*x2 = 0
        # => x2 = -(theta_0 + theta_1*x1) / theta_2
        if abs(theta[2]) > 0.001:  # Avoid division by zero
            x1_line = [x_min, x_max]
            x2_line = [-(theta[0] + theta[1] * x) / theta[2] for x in x1_line]
            ax.plot(x1_line, x2_line, 'g-', linewidth=2, label='Decision Boundary')
        
        # Calculate accuracy at this iteration
        acc = calculate_accuracy(X_data, y_data, theta)
        cost = cost_history[iteration - 1] if iteration > 0 else compute_cost(X_data, y_data, theta)
        
        ax.set_xlim(x_min, x_max)
        ax.set_ylim(-1, 10)
        ax.set_xlabel('x₁')
        ax.set_ylabel('x₂')
        ax.set_title(f'Iteration {iteration}\n'
                     f'Cost={cost:.4f}, Acc={acc:.1f}%\n'
                     f'θ=[{theta[0]:.2f}, {theta[1]:.2f}, {theta[2]:.2f}]',
                     fontsize=10)
        ax.legend(loc='upper left', fontsize=8)
        ax.grid(True, alpha=0.3)
    
    # Hide unused subplots
    for idx in range(len(key_iterations), len(axes)):
        axes[idx].set_visible(False)
    
    plt.suptitle('Decision Boundary Evolution During Training', fontsize=16, y=1.02)
    plt.tight_layout()
    plt.savefig('step4_decision_boundary_evolution.png', dpi=150, bbox_inches='tight')
    plt.show()
    print("  ✓ Saved: step4_decision_boundary_evolution.png")


def visualize_cost_over_iterations(cost_history):
    """
    Visualize how the cost decreases over iterations.
    Shows convergence of gradient descent.
    """
    print("\n📊 STEP 5: Visualizing Cost Function Convergence")
    print("-" * 50)
    
    iterations = list(range(1, len(cost_history) + 1))
    
    fig, axes = plt.subplots(1, 2, figsize=(14, 5))
    
    # Full view
    ax1 = axes[0]
    ax1.plot(iterations, cost_history, 'b-', linewidth=2)
    ax1.set_xlabel('Iteration', fontsize=12)
    ax1.set_ylabel('Cost J(θ)', fontsize=12)
    ax1.set_title('Cost Function Over Iterations (Full View)', fontsize=14)
    ax1.grid(True, alpha=0.3)
    
    # Mark key points
    ax1.axhline(y=cost_history[-1], color='green', linestyle='--', 
                alpha=0.7, label=f'Final cost: {cost_history[-1]:.6f}')
    ax1.axhline(y=cost_history[0], color='red', linestyle='--', 
                alpha=0.7, label=f'Initial cost: {cost_history[0]:.6f}')
    ax1.legend()
    
    # Zoomed view (first 100 iterations where most change happens)
    ax2 = axes[1]
    zoom_range = min(100, len(cost_history))
    ax2.plot(iterations[:zoom_range], cost_history[:zoom_range], 'b-', linewidth=2)
    ax2.set_xlabel('Iteration', fontsize=12)
    ax2.set_ylabel('Cost J(θ)', fontsize=12)
    ax2.set_title('Cost Function (First 100 Iterations - Zoomed)', fontsize=14)
    ax2.grid(True, alpha=0.3)
    
    # Annotate the rapid descent
    ax2.annotate('Rapid descent\n(steep gradient)', 
                 xy=(10, cost_history[9]), xytext=(30, cost_history[5]),
                 fontsize=10, arrowprops=dict(arrowstyle='->', color='red'))
    
    plt.tight_layout()
    plt.savefig('step5_cost_convergence.png', dpi=150)
    plt.show()
    print("  ✓ Saved: step5_cost_convergence.png")


def visualize_theta_evolution(theta_history):
    """
    Visualize how each theta parameter evolves during training.
    """
    print("\n📊 STEP 6: Visualizing Parameter Evolution")
    print("-" * 50)
    
    iterations = list(range(len(theta_history)))
    theta_0_history = [t[0] for t in theta_history]
    theta_1_history = [t[1] for t in theta_history]
    theta_2_history = [t[2] for t in theta_history]
    
    plt.figure(figsize=(12, 5))
    
    plt.subplot(1, 2, 1)
    plt.plot(iterations, theta_0_history, 'r-', linewidth=2, label='θ₀ (bias)')
    plt.plot(iterations, theta_1_history, 'g-', linewidth=2, label='θ₁ (x₁ weight)')
    plt.plot(iterations, theta_2_history, 'b-', linewidth=2, label='θ₂ (x₂ weight)')
    plt.xlabel('Iteration', fontsize=12)
    plt.ylabel('Parameter Value', fontsize=12)
    plt.title('Parameter Evolution During Training', fontsize=14)
    plt.legend()
    plt.grid(True, alpha=0.3)
    
    # Show trajectory in parameter space (theta_1 vs theta_2)
    plt.subplot(1, 2, 2)
    plt.plot(theta_1_history, theta_2_history, 'b-', linewidth=1, alpha=0.7)
    plt.plot(theta_1_history[0], theta_2_history[0], 'go', markersize=12, label='Start')
    plt.plot(theta_1_history[-1], theta_2_history[-1], 'r*', markersize=15, label='End')
    plt.xlabel('θ₁ (x₁ weight)', fontsize=12)
    plt.ylabel('θ₂ (x₂ weight)', fontsize=12)
    plt.title('Gradient Descent Path in Parameter Space', fontsize=14)
    plt.legend()
    plt.grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig('step6_parameter_evolution.png', dpi=150)
    plt.show()
    print("  ✓ Saved: step6_parameter_evolution.png")


def visualize_probability_surface(X_data, y_data, theta):
    """
    Visualize the probability surface and decision regions.
    Shows how the model assigns probabilities across the feature space.
    """
    print("\n📊 STEP 7: Visualizing Probability Surface & Decision Regions")
    print("-" * 50)
    
    # Create mesh grid
    x1_range = np.linspace(-2, 10, 100)
    x2_range = np.linspace(-2, 10, 100)
    X1, X2 = np.meshgrid(x1_range, x2_range)
    
    # Calculate probabilities for each point in the grid
    probs = np.zeros_like(X1)
    for i in range(X1.shape[0]):
        for j in range(X1.shape[1]):
            probs[i, j] = hypothesis([X1[i, j], X2[i, j]], theta)
    
    # Separate classes for plotting
    class_0_x1 = [X_data[i][0] for i in range(len(X_data)) if y_data[i] == 0]
    class_0_x2 = [X_data[i][1] for i in range(len(X_data)) if y_data[i] == 0]
    class_1_x1 = [X_data[i][0] for i in range(len(X_data)) if y_data[i] == 1]
    class_1_x2 = [X_data[i][1] for i in range(len(X_data)) if y_data[i] == 1]
    
    fig, axes = plt.subplots(1, 2, figsize=(14, 6))
    
    # Probability heatmap
    ax1 = axes[0]
    im = ax1.contourf(X1, X2, probs, levels=20, cmap='RdBu', alpha=0.8)
    ax1.contour(X1, X2, probs, levels=[0.5], colors='green', linewidths=3)
    ax1.scatter(class_0_x1, class_0_x2, c='red', marker='o', s=60, 
                edgecolors='white', label='Class 0')
    ax1.scatter(class_1_x1, class_1_x2, c='blue', marker='s', s=60, 
                edgecolors='white', label='Class 1')
    plt.colorbar(im, ax=ax1, label='P(y=1|x)')
    ax1.set_xlabel('x₁', fontsize=12)
    ax1.set_ylabel('x₂', fontsize=12)
    ax1.set_title('Probability Surface\n(P=0.5 line is decision boundary)', fontsize=14)
    ax1.legend(loc='upper left')
    
    # Decision regions
    ax2 = axes[1]
    ax2.contourf(X1, X2, probs >= 0.5, levels=1, colors=['#ffcccc', '#ccccff'], alpha=0.5)
    ax2.contour(X1, X2, probs, levels=[0.5], colors='green', linewidths=3)
    ax2.scatter(class_0_x1, class_0_x2, c='red', marker='o', s=60, 
                edgecolors='darkred', label='Class 0')
    ax2.scatter(class_1_x1, class_1_x2, c='blue', marker='s', s=60, 
                edgecolors='darkblue', label='Class 1')
    ax2.set_xlabel('x₁', fontsize=12)
    ax2.set_ylabel('x₂', fontsize=12)
    ax2.set_title('Decision Regions\n(Red=Predict 0, Blue=Predict 1)', fontsize=14)
    ax2.legend(loc='upper left')
    
    # Add legend patches for regions
    red_patch = mpatches.Patch(color='#ffcccc', alpha=0.5, label='Predict Class 0')
    blue_patch = mpatches.Patch(color='#ccccff', alpha=0.5, label='Predict Class 1')
    ax2.legend(handles=[red_patch, blue_patch] + ax2.get_legend_handles_labels()[0], 
               loc='upper left')
    
    plt.tight_layout()
    plt.savefig('step7_probability_surface.png', dpi=150)
    plt.show()
    print("  ✓ Saved: step7_probability_surface.png")


def visualize_step_by_step_iteration(X_data, y_data, theta, iteration_num):
    """
    Detailed visualization of a single gradient descent iteration.
    Shows exactly what happens in one step.
    """
    print(f"\n📊 Detailed View: Iteration {iteration_num}")
    print("-" * 50)
    
    # Compute current state
    current_cost = compute_cost(X_data, y_data, theta)
    gradients = compute_gradients(X_data, y_data, theta)
    
    print(f"  Current θ = [{theta[0]:.4f}, {theta[1]:.4f}, {theta[2]:.4f}]")
    print(f"  Current Cost = {current_cost:.6f}")
    print(f"  Gradients = [{gradients[0]:.4f}, {gradients[1]:.4f}, {gradients[2]:.4f}]")
    
    # Show predictions for first few points
    print(f"\n  Sample predictions:")
    for i in range(min(5, len(X_data))):
        prob = hypothesis(X_data[i], theta)
        pred = predict(X_data[i], theta)
        correct = "✓" if pred == y_data[i] else "✗"
        print(f"    Point {i}: x={X_data[i]}, P(y=1)={prob:.4f}, "
              f"Predicted={pred}, Actual={y_data[i]} {correct}")


# =============================================================================
# PART 5: MAIN DEMONSTRATION
# =============================================================================

def main():
    """
    Main function demonstrating logistic regression from scratch.
    
    Steps:
    1. Visualize sigmoid function
    2. Generate and visualize training data
    3. Visualize cost function landscape
    4. Train with visualization of each iteration
    5. Show final results and probability surface
    """
    print("=" * 70)
    print("  LOGISTIC REGRESSION FROM SCRATCH - WITH VISUALIZATIONS")
    print("=" * 70)
    print()
    
    # =========================================================================
    # STEP 1: Visualize the Sigmoid Function
    # =========================================================================
    visualize_sigmoid()
    
    # =========================================================================
    # STEP 2: Generate and Visualize Training Data
    # =========================================================================
    print("\n" + "=" * 70)
    print("GENERATING TRAINING DATA")
    print("=" * 70)
    X_train, y_train = generate_sample_data(num_samples=100, seed=42)
    print(f"  - Generated {len(X_train)} training examples")
    print(f"  - Features: {len(X_train[0])} (x1, x2)")
    print(f"  - Class 0 examples: {sum(1 for y in y_train if y == 0)}")
    print(f"  - Class 1 examples: {sum(1 for y in y_train if y == 1)}")
    
    visualize_data(X_train, y_train)
    
    # =========================================================================
    # STEP 3: Visualize Cost Function Landscape
    # =========================================================================
    visualize_cost_function(X_train, y_train)
    
    # =========================================================================
    # STEP 4: Initialize and Train
    # =========================================================================
    print("\n" + "=" * 70)
    print("TRAINING THE MODEL")
    print("=" * 70)
    
    # Initialize parameters
    initial_theta = [0.0, 0.0, 0.0]
    print(f"\nInitial θ = {initial_theta}")
    print(f"Initial Cost = {compute_cost(X_train, y_train, initial_theta):.6f}")
    
    # Show what happens in the first iteration (detailed)
    print("\n" + "-" * 50)
    print("FIRST ITERATION (DETAILED)")
    print("-" * 50)
    visualize_step_by_step_iteration(X_train, y_train, initial_theta, 0)
    
    # Train with gradient descent
    print("\n" + "-" * 50)
    print("RUNNING GRADIENT DESCENT")
    print("-" * 50)
    learning_rate = 0.1
    num_iterations = 1000
    
    final_theta, cost_history, theta_history = gradient_descent(
        X_train, y_train, 
        initial_theta, 
        learning_rate, 
        num_iterations,
        verbose=True
    )
    
    # =========================================================================
    # STEP 5: Visualize Training Progress
    # =========================================================================
    visualize_gradient_descent_iterations(X_train, y_train, theta_history, cost_history)
    visualize_cost_over_iterations(cost_history)
    visualize_theta_evolution(theta_history)
    
    # =========================================================================
    # STEP 6: Final Results
    # =========================================================================
    print("\n" + "=" * 70)
    print("FINAL RESULTS")
    print("=" * 70)
    
    print(f"\nFinal θ = [{final_theta[0]:.4f}, {final_theta[1]:.4f}, {final_theta[2]:.4f}]")
    print(f"Final Cost = {cost_history[-1]:.6f}")
    print(f"Training Accuracy = {calculate_accuracy(X_train, y_train, final_theta):.2f}%")
    
    # =========================================================================
    # STEP 7: Visualize Probability Surface
    # =========================================================================
    visualize_probability_surface(X_train, y_train, final_theta)
    
    # =========================================================================
    # STEP 8: Sample Predictions
    # =========================================================================
    print("\n" + "=" * 70)
    print("SAMPLE PREDICTIONS")
    print("=" * 70)
    
    test_points = [
        [1.0, 1.0],   # Should be class 0
        [7.0, 7.0],   # Should be class 1
        [4.0, 4.0],   # Near boundary
        [3.0, 5.0],   # Ambiguous
    ]
    
    for point in test_points:
        prob = hypothesis(point, final_theta)
        pred = predict(point, final_theta)
        confidence = max(prob, 1 - prob) * 100
        print(f"  Point {point}: P(y=1) = {prob:.4f}, Predicted = {pred}, "
              f"Confidence = {confidence:.1f}%")
    
    # =========================================================================
    # SUMMARY
    # =========================================================================
    print("\n" + "=" * 70)
    print("SUMMARY OF EQUATIONS USED")
    print("=" * 70)
    print("""
1. SIGMOID FUNCTION:
   σ(z) = 1 / (1 + e^(-z))

2. HYPOTHESIS (Probability Prediction):
   h(x) = σ(θ₀ + θ₁x₁ + θ₂x₂ + ... + θₙxₙ)

3. COST FUNCTION (Cross-Entropy Loss):
   J(θ) = -1/m Σ[y·log(h(x)) + (1-y)·log(1-h(x))]

4. GRADIENT (for parameter update):
   ∂J/∂θⱼ = 1/m Σ[(h(x) - y) · xⱼ]

5. GRADIENT DESCENT UPDATE:
   θⱼ := θⱼ - α · ∂J/∂θⱼ
""")
    
    print("=" * 70)
    print("  VISUALIZATION FILES SAVED:")
    print("=" * 70)
    print("  1. step1_sigmoid_function.png")
    print("  2. step2_training_data.png")
    print("  3. step3_cost_landscape.png")
    print("  4. step4_decision_boundary_evolution.png")
    print("  5. step5_cost_convergence.png")
    print("  6. step6_parameter_evolution.png")
    print("  7. step7_probability_surface.png")
    print("=" * 70)


if __name__ == "__main__":
    main()
