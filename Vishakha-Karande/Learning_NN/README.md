1) NOT using NAND
A ──┐
    ├── NAND ──> NOT A
A ──┘

not_a = nand(a, a)


2) AND using NAND
A ──┐
    ├── NAND ──┐
B ──┘          │
               ├── NAND ──> AND
          ─────┘
nand1 = nand(a, b)
and_gate = nand(nand1, nand1)

3) OR Using NAND

A ──┐
    ├── NAND ──> NOT A ──┐
A ──┘                    │
                         ├── NAND ──> OR
B ──┐                    │
    ├── NAND ──> NOT B ──┘
B ──┘

NOT A = NAND(A, A)
NOT B = NAND(B, B)
OR = NAND(NOT A, NOT B)
