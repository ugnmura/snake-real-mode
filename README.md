# Snake Real Mode

Simple Snake implementation inside the boot sector under 512 bytes.

How to run:

```
fasm snake.s snake.bin
qemu-systeem-i386 -fda snake.bin
```
