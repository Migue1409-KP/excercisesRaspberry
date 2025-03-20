// Seccion de datos
        .section .data
        .align 4

// Cadena de ruta a /dev/mem terminada en \0
path:
        .ascii "/dev/mem\0"

// Seccion .text con el codigo
        .section .text
        .align  4
        .global _start

// Direcciones base y offsets para la Pi 4
        .equ  GPIO_BASE,       0xFE200000
        .equ  BLOCK_SIZE,      4096

        // Offsets de los registros
        .equ  GPFSEL1_OFFSET,  0x04   // Para pines 10..19
        .equ  GPSET0_OFFSET,   0x1C
        .equ  GPCLR0_OFFSET,   0x28

// Para el pin 17
        .equ  GPIO17_BIT,      (1 << 17)
        // Bits 21..23 en GPFSEL1 => poner "001" => (1 << 21)

// Numero de syscalls en Linux AArch64
        .equ  SYS_openat,      56
        .equ  SYS_close,       57
        .equ  SYS_mmap,        222
        .equ  SYS_munmap,      215
        .equ  SYS_exit,        93

// Otros valores para openat y mmap
        .equ  AT_FDCWD,        -100
        .equ  O_RDWR,          2

        .equ  PROT_READ,       1
        .equ  PROT_WRITE,      2
        .equ  MAP_SHARED,      1

// Constantes para configurar la funcion de un pin en GPFSEL1
        .equ  GPFSEL1_MASK17,  (0x7 << 21)  // limpia bits 21..23
        .equ  GPFSEL1_OUT17,   (0x1 << 21)  // pone "001" en bits 21..23

// Para las rutinas de delay "software"
        .equ  DELAY_COUNT,     1000000000

/****************************************************************************
 * _start
 *   1) Abre /dev/mem con openat
 *   2) mmap la regiï¿½n de 0xFE200000 (GPIO) en espacio de usuario
 *   3) Configura pin 17 como salida
 *   4) Bucle infinito: enciende LED, espera, apaga LED, espera
 *   5) (Nunca sale, pero podriamos hacer un 'exit' si quisieras)
 ****************************************************************************/
_start:
        //----------------------------------------------------------------------
        // 1) fd = openat(AT_FDCWD, "/dev/mem", O_RDWR, 0)
        //----------------------------------------------------------------------
        mov     x0, AT_FDCWD         // x0 = -100 => "directorio actual"
        adr     x1, path             // x1 = &("/dev/mem")
        mov     x2, O_RDWR           // x2 = flags (lectura/escritura)
        mov     x3, 0                // x3 = modo (sin uso)
        mov     x8, SYS_openat       // x8 = 56 => syscall openat
        svc     #0

        // Comprobar error de openat
        cmp     x0, 0
        blt     error
        mov     x9, x0               // Guardar fd en x9

        //----------------------------------------------------------------------
        // 2) mapeo = mmap(NULL, 4096, PROT_READ|PROT_WRITE, MAP_SHARED, fd, GPIO_BASE)
        //----------------------------------------------------------------------
        mov     x0, 0                // addr = NULL
        mov     x1, BLOCK_SIZE       // length = 4096
        mov     x2, PROT_READ | PROT_WRITE   // prot => R/W
        mov     x3, MAP_SHARED       // flags => MAP_SHARED
        mov     x4, x9               // fd => descriptor de /dev/mem
        mov     x5, GPIO_BASE        // offset => 0xFE200000
        mov     x8, SYS_mmap         // 222 => syscall mmap
        svc     #0

        // Comprobar error de mmap
        cmp     x0, 0
        blt     error
        mov     x19, x0              // x19 = direcciï¿½n base mapeada

        //----------------------------------------------------------------------
        // 3) Configurar GPIO17 como salida (bits 21..23 en GPFSEL1)
        //----------------------------------------------------------------------
        add     x10, x19, GPFSEL1_OFFSET
        ldr     w11, [x10]

        // Limpiar bits 21..23
        mov     w12, #GPFSEL1_MASK17  // (0x7 << 21)
        bic     w11, w11, w12

        // Poner "001" en bits 21..23 => salida
        mov     w12, #GPFSEL1_OUT17   // (1 << 21)
        orr     w11, w11, w12
        str     w11, [x10]

        //----------------------------------------------------------------------
        // 4) Encender y apagar LED con un par de delays
        //----------------------------------------------------------------------

        // Encender LED => escribir en GPSET0
        add     x10, x19, GPSET0_OFFSET
        mov     w11, GPIO17_BIT
        str     w11, [x10]

        // Retardo "on"
        ldr     x2, =DELAY_COUNT
delay_on:
        subs    x2, x2, #1
        bne     delay_on

        // Apagar LED => escribir en GPCLR0
        add     x10, x19, GPCLR0_OFFSET
        mov     w11, GPIO17_BIT
        str     w11, [x10]

        // Retardo "off"
        ldr     x2, =DELAY_COUNT
delay_off:
        subs    x2, x2, #1
        bne     delay_off

        //----------------------------------------------------------------------
        // 5) Salir del programa con exit(0)
        //----------------------------------------------------------------------
        mov     x0, 0
        mov     x8, SYS_exit
        svc     #0

// Si hay error => exit(1)
error:
        mov     x0, 1
        mov     x8, SYS_exit
        svc     #0