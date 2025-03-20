.section .data
mensaje: .asciz "�Hola, Raspberry Pi!\n"

.section .text
.global _start

_start:
    MOV X0, #1          	// Descriptor de archivo (stdout)
    LDR X1, =mensaje   	 // Direcci�n del mensaje
    MOV X2, #20         	// Longitud del mensaje
    MOV X8, #64         	// syscall write
    SVC #0              		// Llamada al sistema

    MOV X0, #0          	// C�digo de salida 0
    MOV X8, #93         	// syscall exit
    SVC #0
