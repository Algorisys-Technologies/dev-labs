# Activation Function
def step_function(x):
    return 1 if x >= 0 else 0


# Matrix Multiplication

def matmul(A, B):
    result = []
    for i in range(len(A)):
        row = []
        for j in range(len(B[0])):
            total = 0
            for k in range(len(B)):
                total += A[i][k] * B[k][j]
            row.append(total)
        result.append(row)
    return result


# Add Bias
def add_bias(matrix, bias):
    result = []
    for row in matrix:
        result.append([row[i] + bias[i] for i in range(len(bias))])
    return result


# Apply Activation
def apply_activation(matrix):
    return [[step_function(x) for x in row] for row in matrix]


# Neural Network Forward Pass
def neural_network(input_data):

    X = [input_data] #2D

    W1 = [
        [1.0, 0.5],   # math score 
        [0.5, 1.0]    # attendance
    ]

    B1 = [-1.0, -1.0]

    Z1 = matmul(X, W1)
    Z1 = add_bias(Z1, B1)
    A1 = apply_activation(Z1)

    # -------- Output Layer --------
    W2 = [
        [1.0],
        [1.0]
    ]

    B2 = [-1.5]

    Z2 = matmul(A1, W2)
    Z2 = add_bias(Z2, B2)
    output = apply_activation(Z2)

    return output[0][0]


# Test the Network
tests = [
    [0, 0],  # poor student
    [1, 0],  # good marks, poor attendance
    [0, 1],  # poor marks, good attendance
    [1, 1]   # good student
]

for t in tests:
    print(f"Input {t} → PASS = {neural_network(t)}")
