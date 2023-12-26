//T c000
lui r7, #c0 

//s b000
lli r0, #71
lui r1, #a2
sw r0, (r1)

lli r0, #71
lui r1, #a1
sw r0, (r1)

//s b000
lui r2, #b0

lui r3, #00

//r7 --> r6 copy
mov r6, r7

//s-loop
//i-loop(y)
lli r5, 16
//j-loop(x)
lli r4, 16

//T(c000) --> r0
lbu r0, (r6)
//s(b000) --> r1
lbu r1, (r2)

sub r0, r1
bmi r0, 6
nop
//+
not r0, r0
addi r0, 1
//-
addi r0, 127
addi r0, 127
addi r0,1

add r3, r0
addi r2, 1

//j-loop last
addi r6, 1 
addi r4, -1
bnez r4, -30
nop

//i-loop last
addi r6, 112 // 次の段
addi r5, -1
bnez r5, -40
nop

//r4,r5==0 --> 1/2
sr r3, r3

//call best(E)
lui r0, #bf
addi r0, 2
lw r1, (r0)

//if best-E
sub r1, r3
bpl r1,8 //+
nop
sw r3, (r0)
addi r0, -2
sw r7, (r0)

addi r7, 1
lui r1, #a1
lw r0, (r1)
addi r0, -1
sw r0, (r1)
bnez r0, -82
nop

addi r7, 15
lui r1, #a2
lw r0, (r1)
addi r0, -1
sw r0, (r1)
bnez r0, -102
nop

lui r5, #bf
lw r7, (r5)
lui r4, #c0
sub r7, r4
//r7 y, r6 x
mov r6, r7

//y
sl r7, r7
sr8 r7, r7
sbu r7, (r5)
//x
addi r5, 1
sl r6, r6
sl r6, r6
sr r6, r6
sr r6, r6
sbu r6, (r5)

nop
nop
nop


//y bf00
SET @bf00 0 0
//x bf01
SET @bf01 0 0
//E bf02
SET @bf02 0 0