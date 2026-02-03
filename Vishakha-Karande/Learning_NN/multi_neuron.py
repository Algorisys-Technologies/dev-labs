#MULTINEURON

inputs=[1,0]
weights=[
    [0.2,0.8], #neuron1
    [0.6,0.3], #neuron2
    [0.4,0.3]  #neuron3
]

bias=[0.1,-0.3,0.6]

def sigmoid(z):
    import math
    return 1/(1+ math.exp(-z))

hidden_output=[]

for n in range(len(weights)):
    z=0
    for i in range(len(inputs)):
        z+=inputs[i]*weights[n][i]

    z+=bias[n]
    hidden_output.append(sigmoid(z))

print(hidden_output)

#MULTILAYER (2 inputs -> 3 hidden neuron -> 1 output neuron)

output_weights = [0.3, 0.6, 0.9]
output_bias = 0.2

z = 0
for i in range(3):
    z += hidden_output[i] * output_weights[i]

z += output_bias
final_output = sigmoid(z)

print(final_output)
