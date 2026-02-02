# supervised learning 
# Years of Experience → Salary


# x = years of experience

# y = actual salary

# w = slope (how much salary increases per year)

# b = bias (base salary)

# y^​=w⋅x+b 

# =========================
# SUPERVISED LEARNING
# LINEAR REGRESSION FROM SCRATCH
# =========================

# 1. Training data (labeled)
# X = years of experience
# y = salary (in thousands)

X = [1, 2, 3, 4, 5]
y = [30, 35, 40, 45, 50]

# 2. Initialize parameters
w = 0.0   # weight (slope)
b = 0.0   # bias (intercept)

# 3. Hyperparameters
learning_rate = 0.01
epochs = 1000
n = len(X)

# 4. Training loop
for epoch in range(epochs):

    # Predictions
    y_pred = []
    for x in X:
        y_pred.append(w * x + b)

    # Compute loss (Mean Squared Error)
    loss = 0
    for i in range(n):
        loss += (y[i] - y_pred[i]) ** 2
    loss = loss / n

    # Compute gradients
    dw = 0
    db = 0
    for i in range(n):
        dw += -2 * X[i] * (y[i] - y_pred[i])
        db += -2 * (y[i] - y_pred[i])

    dw = dw / n
    db = db / n

    # Update parameters
    w = w - learning_rate * dw
    b = b - learning_rate * db

    # Print progress occasionally
    if epoch % 100 == 0:
        print(f"Epoch {epoch}, Loss: {loss:.4f}")

# 5. Final learned parameters
print("\nFinal Model:")
print(f"Salary = {w:.2f} * Experience + {b:.2f}")

# 6. Test on new (unseen) data
new_experience = 6
predicted_salary = w * new_experience + b
print(f"\nPredicted salary for {new_experience} years experience: {predicted_salary:.2f}k")
