use16
format binary
org 0x7C00

macro wait ticks
{
  mov cx, ticks
  xor dx, dx
  mov ah, 86h
  int 15h
}

macro print_video_buffer character
{
  shl di, 1
  mov ax, 0B800h
  mov es, ax
  mov byte [es:di], character
}

WIDTH equ 80
SNAKE_MAX_LEN = WIDTH * 25
HALF_POS = SNAKE_MAX_LEN / 2

GAME_RAM = 0x8000

virtual at GAME_RAM
  pos       rw SNAKE_MAX_LEN
  snake_len rb 1
  dir       rw 1
  pos_apple rw 1
end virtual

main:
  cli
  xor ax, ax
  mov ss, ax
  mov sp, 7C00h
  mov ds, ax
  mov es, ax
  sti

game_start:
  call clear_screen

  mov ah, 02h
  mov bh, 0
  mov dh, 11
  mov dl, 32
  int 10h
  mov si, welcome_msg
  call print

  mov ah, 02h
  mov bh, 0
  mov dh, 13
  mov dl, 29
  int 10h
  mov si, start_msg
  call print

  call get_char_sync

game_init:
  mov word [dir], 1
  mov byte [snake_len], 1
  mov word [pos], HALF_POS
  call update_apple_position

game_loop:
  wait 1
  call clear_screen

  mov di, [pos_apple]
  print_video_buffer 'o'

  call render_snake

  call get_char
  cmp al, 0
  jne input_handled
  cmp ah, 48h
  je press_up
  cmp ah, 4Bh
  je press_left
  cmp ah, 50h
  je press_down
  cmp ah, 4Dh
  je press_right
  jmp input_handled

press_up:
  cmp word [dir], WIDTH
  je input_handled
  mov word [dir], -WIDTH
  jmp input_handled

press_left:
  cmp word [dir], 1
  je input_handled
  mov word [dir], -1
  jmp input_handled

press_down:
  cmp word [dir], -WIDTH
  je input_handled
  mov word [dir], WIDTH
  jmp input_handled

press_right:
  cmp word [dir], -1
  je input_handled
  mov word [dir], 1

input_handled:
  cmp byte [snake_len], 1
  jbe update_snake_head

  xor ax, ax
  mov al, [snake_len]
  dec ax
  shl ax, 1
  mov si, ax
.tail:
  mov ax, [pos + si - 2]
  mov [pos + si], ax
  sub si, 2
  jne .tail

update_snake_head:
  mov ax, [pos]
  xor dx, dx
  mov bx, WIDTH
  div bx

  mov ax, [dir]
  cmp ax, -1
  jne .not_left
  test dx, dx
  jz death
.not_left:
  cmp ax, 1
  jne .move
  cmp dx, WIDTH-1
  je death
.move:
  add [pos], ax

  mov ax, [pos]
  cmp ax, SNAKE_MAX_LEN
  jae death

  cmp byte [snake_len], 1
  jbe check_apple

  mov si, 2
.check:
  mov ax, [pos]
  cmp ax, [pos + si]
  je death
  add si, 2
  xor ax, ax
  mov al, [snake_len]
  shl ax, 1
  cmp si, ax
  jb .check

check_apple:
  mov ax, [pos]
  cmp ax, [pos_apple]
  jne game_loop
  inc byte [snake_len]
  call update_apple_position
  jmp game_loop

render_snake:
  xor ax, ax
  mov al, [snake_len]
  dec ax
  shl ax, 1
  mov si, ax
.loop:
  mov di, [pos + si]
  print_video_buffer 'x'
  or si, si
  jz .done
  sub si, 2
  jmp .loop
.done:
  ret

death:
  call clear_screen
  mov ah, 02h
  mov bh, 0
  mov dh, 12
  mov dl, 35
  int 10h
  mov si, game_over_msg
  call print
  wait 30
  jmp game_start

update_apple_position:
  mov bx, SNAKE_MAX_LEN
  call generate_random_number
  mov [pos_apple], dx
  ret

clear_screen:
  mov ax, 0600h
  mov bh, 1Eh
  mov cx, 0000h
  mov dx, 184Fh
  int 10h
  ret

get_char:
  mov ah, 01h
  int 16h
  jnz get_char_sync
  xor al, al
  ret

get_char_sync:
  mov ah, 00h
  int 16h
  ret

generate_random_number:
  mov ah, 00h
  int 1Ah
  mov ax, dx
  xor dx, dx
  div bx
  ret

print:
  lodsb
  or al, al
  jz .done
  mov ah, 0Eh
  mov bh, 0
  int 10h
  jmp print
.done:
  mov ah, 01h
  mov ch, 20h
  mov cl, 0
  int 10h
  ret

welcome_msg   db 'SNAKE REAL MODE',0
start_msg     db 'Press any key to start',0
game_over_msg db 'GAME OVER!',0

rb 510 - ($ - $$)
db 55h,0AAh
