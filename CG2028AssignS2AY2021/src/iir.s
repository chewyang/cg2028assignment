.syntax unified
   .cpu cortex-m3
   .thumb
   .align 2
   .global  iir
   .thumb_func

@ CG2028 Assignment, Sem 2, AY 2020/21
@ (c) CG2028 Teaching Team, ECE NUS, 2021

@Register map
@R0 - N, returns y
@R1 - b
@R2 - a
@R3 - x_n
@R4 - counter N+1
@R5 - stores y_n values
@R6 - phase 1: values in array b, phase 2: constant & values in y_store
@R7 - phase 1: values in array a, phase 2: values in x_store
@R8 - address of y_store
@R9 - address of x_store
@R10 - phase 1: values in y_store, phase 2: address of y_store from [j-1] onwards
@R11 - phase 1: values in x_store, phase 2: address of x_store from [j-1] onwards

@R4 - N+1

iir:

  @ PUSH / save (only those) registers which are modified by your function
  PUSH {R4-R12};

  ADD R4, R0, #1; @R4 = N+1

  LDR R6, [R1];@, #4; @R4 = value of b[0]
  LDR R7, [R2]; @R5 = value of a[0]

  MUL R5, R3, R6; @x_n * b[0] and store it in R6 (used for value for y_n)

  LDR R8, =y_store; @loads address at y_store into R3 0x1000 0000
  LDR R9, =x_store; @loads address at x_store into R4 0x1000 0030

  PUSH {R7-R9}; @push values of R7-R9 as we only need it later so we can reuse the registers

loop_1:
  LDR R6, [R1, #4]!; @ R4 = b[1++] - pre-indexed addressing 250
  LDR R7, [R2, #4]!; @ R10 = a[1++] - pre-indexed addressing 120

  LDR R10, [R8], #4; @ R10 = y_store[1++]
  LDR R11, [R9], #4; @ R11 = x_store[1++]
  
  MLA R5, R6, R11, R5; @y_n += b[j+1] * x_store[j]
  MLS R5, R7, R10, R5; @y_n -= a[j+1] * y_store[j]

  SUBS R4, #1; @reduce the counter
  BNE loop_1;

  POP {R7-R9}; @getting back the values for a[0], address for y_store and x_store

  SDIV R5, R5, R7; @divide all at once by a[0] after first loop
  @end of first phase, preparing for second phase
  SUB R0, R0, #1; @ changing N counter to N-1 times
  SUB R4, R0, #1; @ changing N+1 counter to N times, to be used to get to array index[j-1]

  @registers not used anymore from first phase: R6,R7,R10,R11,R12;
  MOV R6, #4; @const 4 for making it easier to point to array index

  MLA R10, R4, R6, R8; @ helps to point to array index [j-1] with the counter in R11 and adds to current address of R8
  MLA R11, R4, R6, R9; @ helps to point to array index [j-1] with the counter in R12 and adds to current address of R9

loop_2:
  LDR R6, [R10], #-4; @y_store[j-1]
  LDR R7, [R11], #-4; @x-store[j-1]

  STR R6, [R10, #8]; @ y_store[j] = y_store[j-1];
  STR R7, [R11, #8]; @ x_store[j] = x_store[j-1];

  SUBS R0, #1; @ reduce counter
  BNE loop_2;

  STR R5, [R8]; @ y_store[0] = y_n;
  STR R3, [R9]; @ x_store[0] = x_n;

  MOV R6, #100;
  SDIV R0, R5, R6; @y_n /= 100; // scaling down, assigned to R0 because of return

  POP {R4-R12}; @popping back all register values before method call


@ parameter registers need not be saved.

@ write asm function body here

@ prepare value to return (y_n) to C program in R0

@ POP / restore original register values. DO NOT save or restore R0. Why?

@ return to C program
    BX  LR

@label: .word value
.equ N_MAX, 10
@.lcomm label num_bytes

const4:
  .word 2
.lcomm y_store 4*11
.lcomm x_store 4*11
