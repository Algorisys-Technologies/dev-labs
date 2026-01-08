def step_func(x):
    if x>=0:
        return 1

    else:
        return 0


def NOT_GATE(input,weight):
    total=0
    bias=0.5
    total=input*weight
    total+=bias

    result=step_func(total)
    return result

print(NOT_GATE(1,-1))
