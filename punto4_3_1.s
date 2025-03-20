.section .bss
num1:   .skip 8
num2:   .skip 8

        .section .data
newLine:      .asciz "\n"
mensajeSuma:  .asciz "\n suma:"

        .section .text
        .global _start

_start:
    //------------------------------------------------------------------
    // Leer primer número
    //------------------------------------------------------------------
    MOV X0, #0            // fd=0 => stdin
    LDR X1, =num1         // dirección de num1
    MOV X2, #2            // leer hasta 2 bytes
    MOV X8, #63           // read
    SVC #0

    //------------------------------------------------------------------
    // Leer segundo número
    //------------------------------------------------------------------
    MOV X0, #0
    LDR X1, =num2
    MOV X2, #2
    MOV X8, #63
    SVC #0

    //------------------------------------------------------------------
    // Convertir de ASCII a dígito (solo primer byte)
    //------------------------------------------------------------------
    LDR X2, =num1
    LDRB W4, [X2]         // W4 = primer caracter
    SUB W4, W4, #48       // p.ej. '4' => 4

    LDR X3, =num2
    LDRB W5, [X3]
    SUB W5, W5, #48       // p.ej. '2' => 2

    //----------------------------------------------------------------------
    // Suma
    //----------------------------------------------------------------------
    ADD X6, X4, X5        // X6 = X4 + X5
    ADD X6, X6, #48       // => ASCII

    // Imprimir "\n suma:"
    MOV X0, #1
    LDR X1, =mensajeSuma
    MOV X2, #8
    MOV X8, #64
    SVC #0

    LDR   X1, =num1
    STRB W6, [X1]
    MOV X0, #1
    MOV X2, #1
    MOV X8, #64
    SVC #0

    // Salto de línea final
    MOV X0, #1
    LDR X1, =newLine
    MOV X2, #1
    MOV X8, #64
    SVC #0

    // Salir
    MOV X0, #0
    MOV X8, #93
    SVC #0