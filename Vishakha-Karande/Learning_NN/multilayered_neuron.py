# -------------------------------
# 1. Activation Function
# -------------------------------

def step_function(x):
    if x >= 0:
        return 1
    else:
        return 0


# -------------------------------
# 2. Single Neuron Logic
# -------------------------------

def neuron_output(inputs, weights, bias):
    total = 0
    for i in range(len(inputs)):
        total += inputs[i] * weights[i]
    total += bias
    return step_function(total)


# -------------------------------
# 3. Layer Forward Pass
# -------------------------------

def layer_forward(inputs, weights, biases):
    outputs = []

    for neuron_weights, bias in zip(weights, biases):
        output = neuron_output(inputs, neuron_weights, bias)
        outputs.append(output)

    return outputs


# -------------------------------
# 4. Neural Network Forward Pass
# -------------------------------

def neural_network(inputs):
    # ----- Hidden Layer -----
    hidden_weights = [
        [1, 1],   # Neuron 1
        [1, 0]    # Neuron 2
    ]
    hidden_biases = [-1, -0.5]

    hidden_output = layer_forward(inputs, hidden_weights, hidden_biases)

    # ----- Output Layer -----
    output_weights = [
        [1, 1]
    ]
    output_biases = [-1.5]

    final_output = layer_forward(hidden_output, output_weights, output_biases)

    return final_output[0]


# -------------------------------
# 5. Test the Network
# -------------------------------

test_inputs = [
    [0, 0],
    [1, 0],
    [0, 1],
    [1, 1]
]

for inp in test_inputs:
    result = neural_network(inp)
    print(f"Input: {inp} -> Output: {result}")
