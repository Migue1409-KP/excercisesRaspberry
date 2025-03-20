.section .bss
buffer: .skip 64  // Sólo un buffer, de 64 bytes

.section .data
newLine: .asciz "\n"

.section .text
.global _start

_start:
    //-----------------------------------------------------------
    // Leer el primer mensaje
    //-----------------------------------------------------------
    mov     x0, #0         // stdin
    adrp    x1, buffer     // x1 = dirección base del buffer (parte alta)
    add     x1, x1, :lo12:buffer
    mov     x2, #32
    mov     x8, #63        // syscall read
    svc     #0

    // x0 = bytes leídos
    // Chequeamos el último byte leído por si es '\n'
    mov     x4, x0
    cbz     x4, skip_newline1    // si x4=0 => nada leído
    sub     x4, x4, #1           // x4-- => índice del último byte
    add     x3, x1, x4           // x3 => posición del último byte
    ldrb    w5, [x3]             // leer ese byte
    cmp     w5, #10              // '\n'?
    bne     skip_newline1
    mov     w5, #0               // convertir a terminador de cadena
    strb    w5, [x3]

skip_newline1:

    //-----------------------------------------------------------
    // Buscar el final de la primera cadena en "buffer"
    //-----------------------------------------------------------
    mov     x6, #0               // offset=0
find_end_of_first:
    ldrb    w7, [x1, x6]         // lee un byte buffer[ offset ]
    cmp     w7, #0               // es fin de cadena?
    beq     read_second          // si es 0 => fin
    add     x6, x6, #1
    b       find_end_of_first

    //-----------------------------------------------------------
    // Leer el segundo mensaje en buffer + x6
    //-----------------------------------------------------------
read_second:
    mov     x0, #0     // stdin
    // x1 ya apunta al comienzo del buffer, sumamos x6 => la posición libre
    add     x1, x1, x6
    mov     x2, #32
    mov     x8, #63    // syscall read
    svc     #0

    // Quitar '\n' en la segunda lectura
    mov     x4, x0
    cbz     x4, skip_newline2
    sub     x4, x4, #1
    add     x3, x1, x4
    ldrb    w5, [x3]
    cmp     w5, #10
    bne     skip_newline2
    mov     w5, #0
    strb    w5, [x3]

skip_newline2:

    //-----------------------------------------------------------
    // Imprimir la cadena concatenada
    //-----------------------------------------------------------
    mov     x0, #1         // stdout
    // "buffer" base original
    adrp    x1, buffer
    add     x1, x1, :lo12:buffer
    mov     x2, #64        // max a imprimir
    mov     x8, #64        // syscall write
    svc     #0

    //-----------------------------------------------------------
    // Imprimir salto de línea
    //-----------------------------------------------------------
    mov     x0, #1         // stdout
    adrp    x1, newLine
    add     x1, x1, :lo12:newLine
    mov     x2, #1
    mov     x8, #64        // write
    svc     #0

    //-----------------------------------------------------------
    // Salir
    //-----------------------------------------------------------
    mov     x0, #0
    mov     x8, #93        // exit
    svc     #0