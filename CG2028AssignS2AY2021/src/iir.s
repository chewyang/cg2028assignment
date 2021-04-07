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

@R4 - N+1
@R5 - value needed to be used in array b
@R6 - store value of a[0]
@R7 - used to store for y_n
@R8 - y_store array
@R9 - x_store array
@R10 - value needed to be used in array a from index 1 onwards
@R11 - element in y_store
@R12 - element in x_store

iir:

  @ PUSH / save (only those) registers which are modified by your function
  PUSH {R4-R12};

  MOV R4, R0; @R4 = N
  ADD R4, #1; @R4 = N+1

  LDR R5, [R1];@, #4; @R4 = value of b[0]
  LDR R6, [R2]; @R5 = value of a[0]

  MUL R7, R3, R5; @x_n * b[0] and store it in R6 (used for value for y_n)

  LDR R8, =y_store; @loads address at y_store into R3 0x1000 0000
  LDR R9, =x_store; @loads address at x_store into R4 0x1000 0030
  PUSH {R8-R9};

loop_1:
  LDR R10, [R2, #4]!; @ R10 = a[1++] - pre-indexed addressing 120

  LDR R11, [R8], #4; @ R10 = y_store[1++]
  LDR R12, [R9], #4; @ R11 = x_store[1++]
  LDR R5, [R1, #4]!; @ R4 = b[1++] - pre-indexed addressing 250

  MLA R7, R5, R12, R7; @y_n += b[j+1] * x_store[j]
  MLS R7, R10, R11, R7; @y_n -= a[j+1] * y_store[j]

  SUBS R4, #1; @reduce the counter
  BNE loop_1;

  SDIV R7, R7, R6; @divide all at once by a[0] after first loop
  SUB R0, R0, #1; @ counter = 4-1 = 3
  SUB R4, R0, #1; @ R12 = 3-1 = 2

  POP {R8-R9};
  MOV R5, #4; @const 4 for making it easier to point to array index

  MLA R11, R4, R5, R8; @ helps to point to array index with the counter in R11 and adds to current address of R8
  MLA R12, R4, R5, R9; @ helps to point to array index with the counter in R12 and adds to current address of R9
  @registers that aren't used anymore : R5, R6

loop_2:

  @registers that aren't used anymore : R5, R6, R10, R11, R12

  LDR R5, [R11], #-4; @y_store[j-1]
  LDR R6, [R12], #-4; @x-store[j-1]

  STR R5, [R11, #8]; @ y_store[j] = y_store[j-1];
  STR R6, [R12, #8]; @ x_store[j] = x_store[j-1];

  SUB R4, #1; @ reduce array index
  SUBS R0, #1; @ reduce counter
  BNE loop_2;

  STR R7, [R8]; @ y_store[0] = y_n;
  STR R3, [R9]; @ x_store[0] = x_n;

  MOV R5, #100;
  SDIV R0, R7, R5; @y_n /= 100; // scaling down

  POP {R4-R12};


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
