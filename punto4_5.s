// Sección de datos
        .section .data
        .align 4

// Cadena de ruta a /dev/mem terminada en \0
path:
        .ascii "/dev/mem\0"

// Buffer para leer 1 ó 2 caracteres desde stdin
buffer:
        .space 2

        .section .text
        .align  4
        .global _start

//------------------------------------------------------------------------------
// Direcciones base y offsets GPIO en Raspberry Pi 4
//------------------------------------------------------------------------------
        .equ  GPIO_BASE,      0xFE200000
        .equ  BLOCK_SIZE,     4096

// GPFSEL1 controla GPIO10..19, GPFSEL2 controla GPIO20..29
        .equ  GPFSEL1_OFFSET, 0x04
        .equ  GPFSEL2_OFFSET, 0x08

// GPSET0 y GPCLR0 controlan pines 0..31
        .equ  GPSET0_OFFSET,  0x1C
        .equ  GPCLR0_OFFSET,  0x28

//------------------------------------------------------------------------------
// Definiciones para GPIO17 (rango 10..19 => GPFSEL1)
//------------------------------------------------------------------------------
        .equ  GPIO17_BIT,     (1 << 17)
// GPIO17 usa bits 21..23 dentro de GPFSEL1
        .equ  GPFSEL1_MASK17, (0x7 << 21)
        .equ  GPFSEL1_OUT17,  (0x1 << 21)

//------------------------------------------------------------------------------
// Definiciones para GPIO27 (rango 20..29 => GPFSEL2)
//------------------------------------------------------------------------------
        .equ  GPIO27_BIT,     (1 << 27)
// GPIO27 usa bits 21..23 dentro de GPFSEL2 (27-20=7, 7*3=21)
        .equ  GPFSEL2_MASK27, (0x7 << 21)
        .equ  GPFSEL2_OUT27,  (0x1 << 21)

//------------------------------------------------------------------------------
// Números de syscall en Linux AArch64
//------------------------------------------------------------------------------
        .equ  SYS_openat,     56
        .equ  SYS_read,       63
        .equ  SYS_close,      57
        .equ  SYS_mmap,       222
        .equ  SYS_munmap,     215
        .equ  SYS_exit,       93

// Valores para openat y mmap
        .equ  AT_FDCWD,       -100
        .equ  O_RDWR,         2
        .equ  PROT_READ,      1
        .equ  PROT_WRITE,     2
        .equ  MAP_SHARED,     1

//------------------------------------------------------------------------------
// Constante para retrasos (ajusta según quieras ver el LED encendido / apagado más tiempo)
//------------------------------------------------------------------------------
        .equ  DELAY_COUNT,    3000000

/****************************************************************************
 * _start
 *  1) Abre /dev/mem con openat
 *  2) mmap GPIO_BASE
 *  3) Configura GPIO17 y GPIO27 como salida
 *  4) Lee un dígito (0..9) de STDIN
 *  5) Si es par => enciende/apaga LED en GPIO17, si es impar => GPIO27
 *  6) exit(0)
 ****************************************************************************/
_start:
        //----------------------------------------------------------------------
        // 1) fd = openat(AT_FDCWD, "/dev/mem", O_RDWR, 0)
        //----------------------------------------------------------------------
        mov     x0, AT_FDCWD         // -100 => directorio actual
        adr     x1, path             // &("/dev/mem")
        mov     x2, O_RDWR           // lectura/escritura
        mov     x3, 0                // modo
        mov     x8, SYS_openat       // syscall openat (56)
        svc     #0
        // x0 = fd >=0 si ok, <0 si error
        cmp     x0, 0
        blt     error
        mov     x9, x0               // guardar fd en x9

        //----------------------------------------------------------------------
        // 2) mmap(NULL, BLOCK_SIZE, PROT_READ|PROT_WRITE, MAP_SHARED, fd, GPIO_BASE)
        //----------------------------------------------------------------------
        mov     x0, 0                // addr=NULL
        mov     x1, BLOCK_SIZE       // length=4096
        mov     x2, PROT_READ | PROT_WRITE
        mov     x3, MAP_SHARED
        mov     x4, x9               // fd
        mov     x5, GPIO_BASE        // offset=0xFE200000
        mov     x8, SYS_mmap
        svc     #0
        // x0 = dirección virtual mapeada o <0 si error
        cmp     x0, 0
        blt     error
        mov     x19, x0              // base mapeada

        //----------------------------------------------------------------------
        // 3) Configurar GPIO17 (GPFSEL1) y GPIO27 (GPFSEL2) como salidas
        //----------------------------------------------------------------------
        // --- GPIO17 => GPFSEL1 ---
        add     x10, x19, GPFSEL1_OFFSET
        ldr     w11, [x10]
        mov     w12, #GPFSEL1_MASK17
        bic     w11, w11, w12
        mov     w12, #GPFSEL1_OUT17
        orr     w11, w11, w12
        str     w11, [x10]

        // --- GPIO27 => GPFSEL2 ---
        add     x10, x19, GPFSEL2_OFFSET
        ldr     w11, [x10]
        mov     w12, #GPFSEL2_MASK27
        bic     w11, w11, w12
        mov     w12, #GPFSEL2_OUT27
        orr     w11, w11, w12
        str     w11, [x10]

        //----------------------------------------------------------------------
        // 4) Leer un dígito desde STDIN (fd=0), guardarlo en 'buffer'
        //----------------------------------------------------------------------
        mov     x0, 0                // fd=0 => stdin
        adr     x1, buffer          // destino
        mov     x2, 2               // leer hasta 2 bytes
        mov     x8, SYS_read        // 63 => read
        svc     #0
        // x0 = número de bytes leídos
        cmp     x0, 1
        blt     error               // si no leyó nada, error

        // Tomamos el primer byte
        adr     x1, buffer
        ldrb    w2, [x1]            // w2 = buffer[0]

        // Verificar que sea '0'..'9': ASCII 48..57
        // if (w2 < '0') => error, if (w2 > '9') => error
        cmp     w2, #'0'
        blt     error
        cmp     w2, #'9'
        bgt     error

        // Convertir a valor 0..9 => w2 -= '0'
        sub     w2, w2, #'0'

        // Determinar par/impar => w2 & 1
        and     w3, w2, #1
        cbz     w3, is_even      // si w3=0 => par
        b       is_odd

//------------------------------------------------------------------------------
// 5) Acciones si es par => Encender y apagar LED17
//------------------------------------------------------------------------------
is_even:
        // Encender LED17 => GPSET0
        add     x10, x19, GPSET0_OFFSET
        mov     w11, GPIO17_BIT
        str     w11, [x10]

        // Delay "encendido"
        ldr     x2, =DELAY_COUNT
delay_par_on:
        subs    x2, x2, #1
        bne     delay_par_on

        // Apagar LED17 => GPCLR0
        add     x10, x19, GPCLR0_OFFSET
        mov     w11, GPIO17_BIT
        str     w11, [x10]

        // Delay "apagado"
        ldr     x2, =DELAY_COUNT
delay_par_off:
        subs    x2, x2, #1
        bne     delay_par_off

        b       done

//------------------------------------------------------------------------------
// 5b) Acciones si es impar => Encender y apagar LED27
//------------------------------------------------------------------------------
is_odd:
        // Encender LED27 => GPSET0
        add     x10, x19, GPSET0_OFFSET
        mov     w11, GPIO27_BIT
        str     w11, [x10]

        // Delay "encendido"
        ldr     x2, =DELAY_COUNT
delay_impar_on:
        subs    x2, x2, #1
        bne     delay_impar_on

        // Apagar LED27 => GPCLR0
        add     x10, x19, GPCLR0_OFFSET
        mov     w11, GPIO27_BIT
        str     w11, [x10]

        // Delay "apagado"
        ldr     x2, =DELAY_COUNT
delay_impar_off:
        subs    x2, x2, #1
        bne     delay_impar_off

        b       done

//------------------------------------------------------------------------------
done:
        // 6) exit(0)
        mov     x0, 0
        mov     x8, SYS_exit
        svc     #0

// Si algo falla => exit(1)
error:
        mov     x0, 1
        mov     x8, SYS_exit
        svc     #0