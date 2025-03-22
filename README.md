# Taller de Ensamblador en Raspberry Pi

Este repositorio contiene todas las soluciones (sufijos .s) del taller, abarcando los puntos **4.1.1**, **4.1.2**, **4.2.1**, **4.2.2**, **4.3.1**, **4.3.2**, **4.4.1**, **4.4.2** y **4.5**. Cada uno es un ejercicio de ensamblador (ARM / ARM64) que realiza diferentes tareas, desde lecturas y operaciones en modo usuario hasta acceso directo a GPIO (para Raspberry Pi).

> **Importante**: En los ejercicios que acceden directamente a 0xFE200000 (GPIO), si se ejecutan en un Linux normal (userland), se producirá un **segfault** (violación de segmento) al no tener permisos/mapeo a esa dirección física. Para hacerlo en userland sin segfault:
> - Usar un driver como **/dev/gpiomem** (mapeando la zona del GPIO).
> - O un entorno **bare-metal** (sin SO).
> - O bien un **módulo** / driver en espacio **kernel**.

## Alias para compilar y ejecutar

Agrega estos alias a tu `~/.bashrc` (o al shell actual) para compilar y ejecutar fácilmente:

```bash
alias procesarArchivo='function _procesarArchivo() {
  as -o "$1.o" "$1.s" && ld -o "$1" "$1.o" && ./"$1";
}; _procesarArchivo'

alias procesarArchivo2='function _procesarArchivo2() {
  aarch64-linux-gnu-as -o "$1.o" "$1.s" && aarch64-linux-gnu-ld -o "$1" "$1.o" && sudo ./"$1";
}; _procesarArchivo2'
```

-----

## 4.1.1
**Enunciado:** Se pide leer un dígito para cada número, convertirlo de ASCII a entero, realizar una operación (por ejemplo, suma) y mostrar el resultado en un único dígito ASCII.

## 4.1.2
**Enunciado:** Similar a 4.1.1 pero amplía la operación (puede incluir resta) o imprime más mensajes. Manejo básico de ASCII con un dígito.

## 4.2.1
**Enunciado:** Leer un texto (por ejemplo hasta 32 bytes) y luego imprimirlo (posiblemente con una pequeña modificación).

## 4.2.2
**Enunciado:** Leer dos mensajes, cada uno en su buffer, quitar \n si procede y concatenarlos. Posteriormente, mostrar la cadena resultante en pantalla.

## 4.3.1
**Enunciado:** Pedir 2 números de 1 dígito y realizar operación (suma). El resultado debe ser de 1 dígito ASCII.

## 4.3.2
**Enunciado:** Pedir 2 números de 1 dígito y realizar operación (suma, resta, multiplicación y división). El resultado debe ser de 1 dígito ASCII.

## 4.4.1
**Enunciado:** Acceso directo a GPIO (0xFE200000) en Raspberry Pi 4, configurando GPIO17 como salida y parpadeando un LED mediante bucles de retardo.
>Se ensambla con procesarArchivo2.

## 4.4.2
**Enunciado:** Similar a 4.4.1, pero manejando dos LEDs.
>Se ensambla con procesarArchivo2.

## 4.5
**Enunciado:** Leer un número y encender un LED u otro dependiendo de la paridad. Requiere acceso a GPIO.
>Se ensambla con procesarArchivo2.
