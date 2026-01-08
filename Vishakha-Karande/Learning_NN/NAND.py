def step_function(total):
    return 1 if total>=0 else 0

def NAND(inputs):
    total=0
    bias=1.5
    weights=[-1,-1]
    for i,j in inputs,weights:
        total+=i*j
        total+=bias

    return step_function(total)
    

print(NAND([1,1]))