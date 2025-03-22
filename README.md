# Taller de Ensamblador en Raspberry Pi

Este repositorio contiene todas las soluciones (sufijos .s) del taller, abarcando los puntos 4.1.1, 4.1.2, 4.2.1, 4.2.2, 4.3.1, 4.3.2, 4.4.1, 4.4.2 y 4.5. Cada uno es un ejercicio de ensamblador (ARM / ARM64) que realiza diferentes tareas, desde lecturas y operaciones en modo usuario hasta acceso directo a GPIO (para Raspberry Pi).

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
