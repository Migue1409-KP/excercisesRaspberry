.section .bss
num1:   .skip 8
num2:   .skip 8

        .section .data
newLine:      .asciz "\n"
mensajeSuma:  .asciz "\n suma:"
mensajeResta: .asciz "\n resta:"
mensajeMulti: .asciz "\n multi:"
mensajeDiv:   .asciz "\n div:"

        .section .text
        .global _start

/**********************************************************************
 * _start:
 *  1) Leer primer número (1-2 bytes) en num1
 *  2) Leer segundo número (1-2 bytes) en num2
 *  3) Convertir ambos de ASCII a dígito (0..9)
 *  4) Mostrar resultados de:
 *      - Suma
 *      - Resta
 *      - Multiplicación
 *      - División
 *  5) Salir
 **********************************************************************/
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

    //----------------------------------------------------------------------
    // Resta
    //----------------------------------------------------------------------
    MOV X0, #1
    LDR X1, =mensajeResta
    MOV X2, #8
    MOV X8, #64
    SVC #0

    SUB X6, X4, X5
    ADD X6, X6, #48

    LDR   X1, =num1
    STRB W6, [X1]
    MOV X0, #1
    MOV X2, #1
    MOV X8, #64
    SVC #0

    //----------------------------------------------------------------------
    // Multiplicación
    //----------------------------------------------------------------------
    MOV X0, #1
    LDR X1, =mensajeMulti
    MOV X2, #8
    MOV X8, #64
    SVC #0

    MUL X6, X4, X5
    ADD X6, X6, #48

    LDR   X1, =num1
    STRB W6, [X1]
    MOV X0, #1
    MOV X2, #1
    MOV X8, #64
    SVC #0

    //----------------------------------------------------------------------
    // División
    //----------------------------------------------------------------------
    MOV X0, #1
    LDR X1, =mensajeDiv
    MOV X2, #8
    MOV X8, #64
    SVC #0

    SDIV X6, X4, X5
    ADD X6, X6, #48


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