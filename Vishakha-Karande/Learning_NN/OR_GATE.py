def step_func(x):
    if x>=0:
        return 1

    else:
        return 0


def OR_GATE(inputs,weights):
    total=0
    bias=-0.5
    for i,j in inputs, weights:
        total+=i*j
    total+=bias

    result=step_func(total)
    return result

print(OR_GATE([1,0],[1,1]))
