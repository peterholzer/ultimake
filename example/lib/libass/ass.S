    .file   "ass.S"
    .section    .rodata
.LC0:
    .string "printFunction3()"
    .text
    .globl  printFunction3
    .type   printFunction3, @function
printFunction3:
.LFB0:
    .cfi_startproc
    pushq   %rbp
    .cfi_def_cfa_offset 16
    .cfi_offset 6, -16
    movq    %rsp, %rbp
    .cfi_def_cfa_register 6
    movl    $.LC0, %edi
    movl    $0, %eax
    call    printf
    nop
    popq    %rbp
    .cfi_def_cfa 7, 8
    ret
    .cfi_endproc
.LFE0:
    .size   printFunction3, .-printFunction3
    .section    .rodata
.LC1:
    .string "printFunction4()"
    .text
    .globl  printFunction4
    .type   printFunction4, @function
printFunction4:
.LFB1:
    .cfi_startproc
    pushq   %rbp
    .cfi_def_cfa_offset 16
    .cfi_offset 6, -16
    movq    %rsp, %rbp
    .cfi_def_cfa_register 6
    movl    $.LC1, %edi
    movl    $0, %eax
    call    printf
    nop
    popq    %rbp
    .cfi_def_cfa 7, 8
    ret
    .cfi_endproc
.LFE1:
    .size   printFunction4, .-printFunction4
    .ident  "GCC: (Debian 5.3.1-21) 5.3.1 20160528"
    .section    .note.GNU-stack,"",@progbits
