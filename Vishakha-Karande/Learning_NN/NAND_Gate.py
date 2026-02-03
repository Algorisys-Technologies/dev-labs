#Activation Function
def step(z):
    if z >= 0:
        return 1
    else:
        return 0


#Neuron Class
class Neuron:
    def __init__(self, w1, w2, bias):
        self.w1 = w1
        self.w2 = w2
        self.bias = bias

    def forward(self, x1, x2):
        z = (self.w1 * x1) + (self.w2 * x2) + self.bias
        return step(z)


# Step 3: Attendance Neural Network
# (Single NAND Neuron)
class AttendanceNetwork:
    def __init__(self):
        # NAND configuration
        self.neuron = Neuron(
            w1=-1,
            w2=-1,
            bias=1.5
        )

    def predict(self, absent, no_medical):
        return self.neuron.forward(absent, no_medical)



# Step 4: Test the Network
if __name__ == "__main__":

    network = AttendanceNetwork()

    test_cases = [
        ("Absent & No Medical", 1, 1),
        ("Absent & Medical", 1, 0),
        ("Present & No Medical", 0, 1),
        ("Present & Medical", 0, 0)
    ]

    print("Student Attendance Decision")
    print("---------------------------")
    print("     Case    |       Approved")
    print("---------------------------")

    for case, absent, no_medical in test_cases:
        result = network.predict(absent, no_medical)
        decision = "YES" if result == 1 else "NO"
        print(f"{case} | {decision}")
