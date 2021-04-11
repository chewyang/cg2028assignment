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

  PUSH {R4-R12};

  ADD R4, R0, #1; @0x02804001

  LDR R6, [R1]; @0x05116000
  LDR R7, [R2]; @0x05127000

  MUL R5, R3, R6; @0x00005613

  LDR R8, =y_store; 
  LDR R9, =x_store;

  PUSH {R7-R9};

loop_1:
  LDR R6, [R1, #4]!; @0x05916004
  LDR R7, [R2, #4]!; @0x05927004

  LDR R10, [R8], #4; @0x0498A004
  LDR R11, [R9], #4; @0x0499B004
  
  MLA R5, R6, R11, R5; @0x00255B17
  MLS R5, R7, R10, R5;

  SUBS R4, R4, #1; @0x02544001
  BNE loop_1; @0x18000020

  POP {R7-R9};

  SDIV R5, R5, R7;

  @end of first phase, preparing for second phase

  SUB R0, R0, #1; @0x02400001
  SUB R4, R0, #1; @02404001

  MOV R6, #4; @0x03A06004
  MLA R10, R4, R6, R8; @0x0028A614
  MLA R11, R4, R6, R9; @0x0029B614

loop_2:
  LDR R6, [R10], #-4; @0x041A6004
  LDR R7, [R11], #-4; @0x041B7004

  STR R6, [R10, #8]; @0x058A6008
  STR R7, [R11, #8]; @0x058B7008

  SUBS R0,R0, #1; @0x02500001
  BNE loop_2; @0x18000018

  STR R5, [R8]; @0x05885000
  STR R3, [R9]; @0x05893000

  MOV R6, #100; @0x03A06064
  SDIV R0, R5, R6;

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
.lcomm y_store 4*N_MAX
.lcomm x_store 4*N_MAX
