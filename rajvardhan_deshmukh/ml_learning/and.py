# AND Gate Neural Network (NO LIBRARIES)

def step(x):
    if x >= 0:
        return 1
    else:
        return 0

# Training data
data = [
    ([0, 0], 0),
    ([0, 1], 0),
    ([1, 0], 0),
    ([1, 1], 1),
]

# Initialize parameters
w1 = 1.0
w2 = 0.0
bias = 0.0

lr = 0.1
epochs = 10

# Training
for epoch in range(epochs):
    print("\nEpoch:", epoch)
    for inputs, target in data:
        x1, x2 = inputs

        weighted_sum = x1*w1 + x2*w2 + bias
        output = step(weighted_sum)

        error = target - output

        w1 = w1 + lr * error * x1
        w2 = w2 + lr * error * x2
        bias = bias + lr * error

        print(f"Input:{inputs} Target:{target} Output:{output} Error:{error}")
        print(f"Weights: w1={w1:.2f}, w2={w2:.2f}, bias={bias:.2f}")

# Testing
print("\nFinal AND Gate Results:")
for inputs, _ in data:
    x1, x2 = inputs
    result = step(x1*w1 + x2*w2 + bias)
    print(f"{inputs} -> {result}")
