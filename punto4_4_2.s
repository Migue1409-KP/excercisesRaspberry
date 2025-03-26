// Sección de datos
.section .data
.align 4

// Cadena de ruta a /dev/mem terminada en \0
path:
        .ascii "/dev/mem\0"

// Sección .text con el código
        .section .text
        .align  4
        .global _start

//--------------------------------------------------------------------------
// Direcciones base y offsets GPIO en Raspberry Pi 4
//--------------------------------------------------------------------------
        .equ  GPIO_BASE,       0xFE200000
        .equ  BLOCK_SIZE,      4096

// GPFSEL1 controla GPIO10..19, GPFSEL2 controla GPIO20..29
        .equ  GPFSEL1_OFFSET,  0x04
        .equ  GPFSEL2_OFFSET,  0x08

// GPSET0 y GPCLR0 controlan pines 0..31
        .equ  GPSET0_OFFSET,   0x1C
        .equ  GPCLR0_OFFSET,   0x28

//--------------------------------------------------------------------------
// Definiciones para GPIO17 (rango 10..19 => GPFSEL1)
//--------------------------------------------------------------------------
// Bits para GPIO17 = bits 21..23 en GPFSEL1
        .equ  GPIO17_BIT,      (1 << 17)
        .equ  GPFSEL1_MASK17,  (0x7 << 21)
        .equ  GPFSEL1_OUT17,   (0x1 << 21)

//--------------------------------------------------------------------------
// Definiciones para GPIO27 (rango 20..29 => GPFSEL2)
//--------------------------------------------------------------------------
// GPIO27 usa bits 21..23 en GPFSEL2 (porque 27-20=7, 7*3=21)
        .equ  GPIO27_BIT,      (1 << 27)
        .equ  GPFSEL2_MASK27,  (0x7 << 21)
        .equ  GPFSEL2_OUT27,   (0x1 << 21)

//--------------------------------------------------------------------------
// Números de syscall en Linux AArch64
//--------------------------------------------------------------------------
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

// Ajusta este valor para el tiempo encendido/apagado (cuanto más grande, más lento)
        .equ  DELAY_COUNT,     3000000

/****************************************************************************
 * _start
 *   1) Abre /dev/mem con openat
 *   2) mmap de la región 0xFE200000 (GPIO)
 *   3) Configura GPIO17 y GPIO27 como salida
 *   4) Enciende los dos LEDs, espera, apaga los dos LEDs, espera
 *   5) exit(0)
 ****************************************************************************/
_start:
        //----------------------------------------------------------------------
        // 1) fd = openat(AT_FDCWD, "/dev/mem", O_RDWR, 0)
        //----------------------------------------------------------------------
        mov     x0, AT_FDCWD       // -100 => "directorio actual"
        adr     x1, path           // puntero a "/dev/mem"
        mov     x2, O_RDWR         // flags = lectura/escritura
        mov     x3, 0              // modo sin uso
        mov     x8, SYS_openat     // syscall openat (56)
        svc     #0

        // Comprobamos error al abrir
        cmp     x0, 0
        blt     error
        mov     x9, x0             // x9 = fd

        //----------------------------------------------------------------------
        // 2) mapeo = mmap(NULL, BLOCK_SIZE, PROT_READ|PROT_WRITE, MAP_SHARED, fd, GPIO_BASE)
        //----------------------------------------------------------------------
        mov     x0, 0              // addr = NULL
        mov     x1, BLOCK_SIZE     // length = 4096
        mov     x2, PROT_READ | PROT_WRITE
        mov     x3, MAP_SHARED
        mov     x4, x9             // fd = el de /dev/mem
        mov     x5, GPIO_BASE      // offset = 0xFE200000
        mov     x8, SYS_mmap       // syscall mmap (222)
        svc     #0

        // Comprobamos error de mmap
        cmp     x0, 0
        blt     error
        mov     x19, x0            // x19 = dirección base mapeada

        //----------------------------------------------------------------------
        // 3) Configurar GPIO17 como salida (GPFSEL1)
        //----------------------------------------------------------------------
        add     x10, x19, GPFSEL1_OFFSET
        ldr     w11, [x10]

        // Limpiar bits 21..23 (GPIO17)
        mov     w12, #GPFSEL1_MASK17
        bic     w11, w11, w12

        // Poner "001" => salida
        mov     w12, #GPFSEL1_OUT17
        orr     w11, w11, w12
        str     w11, [x10]

        //----------------------------------------------------------------------
        // 3b) Configurar GPIO27 como salida (GPFSEL2)
        //----------------------------------------------------------------------
        add     x10, x19, GPFSEL2_OFFSET
        ldr     w11, [x10]

        // Limpiar bits 21..23 (GPIO27)
        mov     w12, #GPFSEL2_MASK27
        bic     w11, w11, w12

        // Poner "001" => salida
        mov     w12, #GPFSEL2_OUT27
        orr     w11, w11, w12
        str     w11, [x10]

        //----------------------------------------------------------------------
        // 4) Encender ambos LEDs, delay, apagar ambos LEDs, delay, luego salir
        //----------------------------------------------------------------------

        // Encender LED17 y LED27 => GPSET0 (pin < 32)
        add     x10, x19, GPSET0_OFFSET

        // Ponemos en w11 el "bit mask" de ambos pines: (1 << 17) | (1 << 27)
        mov     w11, GPIO17_BIT
        orr     w11, w11, #(GPIO27_BIT)

        // Escritura => los dos pines se ponen en alto
        str     w11, [x10]

        // Delay "on"
        ldr     x2, =DELAY_COUNT
delay_on:
        subs    x2, x2, #1
        bne     delay_on

        // Apagar LED17 y LED27 => GPCLR0
        add     x10, x19, GPCLR0_OFFSET

        // Misma máscara: (1 << 17) + (1 << 27)
        mov     w11, GPIO17_BIT
        orr     w11, w11, #(GPIO27_BIT)

        // Escritura => los dos pines se ponen en bajo
        str     w11, [x10]

        // Delay "off"
        ldr     x2, =DELAY_COUNT
delay_off:
        subs    x2, x2, #1
        bne     delay_off

        // 5) Salir del programa con exit(0)
        mov     x0, 0
        mov     x8, SYS_exit
        svc     #0

// Si hay error => exit(1)
error:
        mov     x0, 1
        mov     x8, SYS_exit
        svc     #0
