def step_func(x):
    if x>=0:
        return 1

    else:
        return 0


def AND_GATE(inputs,weights):
    total=0
    bias=-1.5
    for i,j in inputs, weights:
        total+=i*j
    total+=bias

    result=step_func(total)
    return result

print(AND_GATE([1,2],[1,1]))
