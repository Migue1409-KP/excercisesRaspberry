.section .bss
buffer: .skip 32  		// Espacio para almacenar el mensaje

.section .text
.global _start

_start:
    MOV X0, #0          	// stdin
    LDR X1, =buffer    	 // Direcci�n del buffer
    MOV X2, #32         	// Leer hasta 32 caracteres
    MOV X8, #63        	 // syscall read
    SVC #0

    MOV X0, #1          	// stdout
    LDR X1, =buffer     	// Imprimir el buffer le�do
    MOV X2, #32
    MOV X8, #64         	// syscall write
    SVC #0

    MOV X0, #0
    MOV X8, #93         	// syscall exit
    SVC #0
