org 100h

section .text

start:
    call init_video
    call load_high_score      ; Load High Score from file
    call reset_game_variables
    call init_bricks
    
    ; Show Welcome Screen
    call show_welcome
    call wait_for_menu_input
    
    ; Initialize Game Screen
    call clear_screen
    call draw_status
    call draw_bricks
    
    ; Initialize Paddle & Ball
    call reset_positions

game_loop:
    call check_input
    
    ; Update Ball
    call clear_ball
    call update_ball
    call draw_ball
    
    call delay
    jmp game_loop

exit_label:
    call save_high_score      ; Save High Score before exit
    call restore_video
    call exit_program

; ------------------------------------------------------------------------------
; Procedures
; ------------------------------------------------------------------------------

init_video:
    mov ax, 0013h
    int 10h
    mov ax, 0A000h
    mov es, ax
    ret

restore_video:
    mov ax, 0003h
    int 10h
    ret

clear_screen:
    push es
    mov ax, 0A000h
    mov es, ax
    xor di, di
    xor al, al
    mov cx, 320*200
    rep stosb
    pop es
    ret

reset_game_variables:
    mov word [score], 0
    mov word [lives], 3
    mov word [level], 1
    mov word [game_speed], START_SPEED
    mov word [bricks_remaining], TOTAL_BRICKS
    ret

init_bricks:
    ; Initialize bricks with types based on rows
    ; Row 0: Type 4 (Yellow) - Top
    ; Row 1: Type 3 (Red)
    ; Row 2: Type 2 (Green)
    ; Row 3: Type 1 (Blue) - Bottom
    
    mov bx, 0
    mov cx, BRICK_ROWS
    mov al, 4           ; Start with Type 4
    
.row_init_loop:
    push cx
    mov cx, BRICK_COLS
.col_init_loop:
    mov byte [brick_array + bx], al
    inc bx
    loop .col_init_loop
    
    dec al              ; Next row type
    pop cx
    loop .row_init_loop
    
    mov word [bricks_remaining], TOTAL_BRICKS
    call init_brick_offsets
    ret

init_brick_offsets:
    ; Pre-calculate video memory offsets for all bricks
    ; Store in brick_offsets array (2 bytes per brick)
    
    mov cx, TOTAL_BRICKS
    mov bx, 0           ; Brick Index
    
.offset_loop:
    push cx
    push bx
    
    ; Calculate Row = Index / Cols
    mov ax, bx
    mov cl, BRICK_COLS
    div cl              ; AL = Row, AH = Col
    
    ; Save Col (AH) on STACK because MUL destroys DX
    xor dx, dx
    mov dl, ah          ; DL = Col
    push dx             ; SAVE COL
    
    xor ah, ah          ; AX = Row
    
    ; Calculate Y = Row * (HEIGHT + GAP) + START_Y
    mov cx, BRICK_HEIGHT + BRICK_GAP
    mul cx
    add ax, START_Y
    push ax             ; Save Y
    
    ; Calculate X = Col * (WIDTH + GAP) + START_X
    pop ax              ; Peek Y (wait, we need Col first)
    pop dx              ; RESTORE COL
    push ax             ; Put Y back on stack
    
    mov al, dl          ; AL = Col
    xor ah, ah
    mov cx, BRICK_WIDTH + BRICK_GAP
    mul cx
    add ax, START_X
    mov si, ax          ; SI = X
    
    pop ax              ; Restore Y (AX)
    
    ; Calculate Offset = Y * 320 + X
    mov cx, 320
    mul cx              ; DX:AX = Y * 320
    add ax, si          ; AX = Offset
    
    ; Store in array
    pop bx              ; Restore Index
    shl bx, 1           ; Index * 2 (word array)
    mov [brick_offsets + bx], ax
    shr bx, 1           ; Restore Index
    
    pop cx
    inc bx
    loop .offset_loop
    ret

reset_positions:
    mov word [paddle_x], START_PADDLE_X
    mov word [ball_x], START_BALL_X
    mov word [ball_y], START_BALL_Y
    mov word [ball_vel_x], 2
    mov word [ball_vel_y], -2
    
    call draw_paddle
    call draw_ball
    ret

draw_status:
    ; Draw Score
    mov dh, 24
    mov dl, 1
    call set_cursor
    mov bp, score_msg
    mov cx, score_len
    mov bl, 0Fh
    call print_string
    mov ax, [score]
    call print_number
    
    ; Draw Lives
    mov dh, 24
    mov dl, 15
    call set_cursor
    mov bp, lives_msg
    mov cx, lives_len
    mov bl, 0Fh
    call print_string
    mov ax, [lives]
    call print_number
    
    ; Draw Level
    mov dh, 24
    mov dl, 25
    call set_cursor
    mov bp, level_msg
    mov cx, level_len
    mov bl, 0Fh
    call print_string
    mov ax, [level]
    call print_number
    
    ; Draw High Score
    mov dh, 24
    mov dl, 32
    call set_cursor
    mov bp, hi_msg
    mov cx, hi_len
    mov bl, 0Eh     ; Yellow
    call print_string
    mov ax, [high_score]
    call print_number
    ret

set_cursor:
    push ax
    push bx
    mov ah, 02h
    mov bh, 0
    int 10h
    pop bx
    pop ax
    ret

print_string:
    push ax
    push bx
    push cx
    push dx
    push es
    push ds
    pop es
    mov ax, 1301h
    mov bh, 0
    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    push si
    mov si, bp
.print_loop:
    mov al, [si]
    mov ah, 0Eh
    int 10h
    inc si
    loop .print_loop
    pop si
    ret

print_number:
    push ax
    push bx
    push cx
    push dx
    mov bx, 10
    xor cx, cx
.div_loop:
    xor dx, dx
    div bx
    push dx
    inc cx
    cmp ax, 0
    jne .div_loop
.print_digits:
    pop ax
    add al, '0'
    mov ah, 0Eh
    mov bl, 0Fh
    int 10h
    loop .print_digits
    pop dx
    pop cx
    pop bx
    pop ax
    ret

update_score:
    ; Input: AX = Points to add
    add word [score], ax
    
    ; Check High Score
    mov ax, [score]
    cmp ax, [high_score]
    jle .skip_hi
    mov [high_score], ax
.skip_hi:
    call draw_status
    ret

lose_life:
    call sound_loss
    dec word [lives]
    call draw_status
    
    cmp word [lives], 0
    je show_lose_screen
    
    call clear_paddle
    call clear_ball
    call reset_positions
    call wait_for_key
    ret

next_level:
    ; Increase Level
    inc word [level]
    
    ; Increase Speed (Decrease delay)
    mov ax, [game_speed]
    sub ax, 500         ; Decrease delay by 500
    cmp ax, 1000        ; Min delay
    jge .set_speed
    mov ax, 1000
.set_speed:
    mov [game_speed], ax
    
    ; Reset Bricks
    call init_bricks
    
    ; Reset Positions
    call clear_screen
    call draw_status
    call draw_bricks
    call reset_positions
    
    ; Wait for key to start level
    call wait_for_key
    ret

show_lose_screen:
    call save_high_score    ; Save on lose
    call clear_screen
    
    mov bp, lose_msg
    mov cx, lose_len
    mov dh, 10
    mov dl, 15
    mov bl, 0Ch
    call draw_text
    
    mov bp, score_msg
    mov cx, score_len
    mov dh, 12
    mov dl, 15
    mov bl, 0Fh
    call draw_text
    
    mov dh, 12
    mov dl, 22
    call set_cursor
    mov ax, [score]
    call print_number
    
    mov bp, restart_msg
    mov cx, restart_len
    mov dh, 15
    mov dl, 5
    mov bl, 07h
    call draw_text
    
    jmp wait_for_restart

wait_for_restart:
    mov ah, 00h
    int 16h
    cmp al, 'y'
    je restart_game
    cmp al, 'Y'
    je restart_game
    cmp al, 'n'
    je exit_label_jump
    cmp al, 'N'
    je exit_label_jump
    jmp wait_for_restart

restart_game:
    call reset_game_variables
    call init_bricks
    call clear_screen
    call draw_status
    call draw_bricks
    call reset_positions
    jmp game_loop

exit_label_jump:
    jmp exit_label

; ------------------------------------------------------------------------------
; File I/O
; ------------------------------------------------------------------------------

load_high_score:
    ; Open File
    mov ah, 3Dh
    mov al, 0           ; Read Only
    mov dx, filename
    int 21h
    jc .load_fail       ; Carry set on error
    
    mov bx, ax          ; File Handle
    
    ; Read 2 bytes
    mov ah, 3Fh
    mov cx, 2
    mov dx, high_score
    int 21h
    
    ; Close File
    mov ah, 3Eh
    int 21h
    ret

.load_fail:
    mov word [high_score], 0
    ret

save_high_score:
    ; Create/Truncate File
    mov ah, 3Ch
    mov cx, 0           ; Normal attributes
    mov dx, filename
    int 21h
    jc .save_fail
    
    mov bx, ax          ; File Handle
    
    ; Write 2 bytes
    mov ah, 40h
    mov cx, 2
    mov dx, high_score
    int 21h
    
    ; Close File
    mov ah, 3Eh
    int 21h
    ret

.save_fail:
    ret

; ------------------------------------------------------------------------------
; Audio
; ------------------------------------------------------------------------------

play_sound:
    push ax
    push bx
    push cx
    push dx
    mov al, 0B6h
    out 43h, al
    mov dx, 12h
    mov ax, 34DCh
    div di
    out 42h, al
    mov al, ah
    out 42h, al
    in al, 61h
    mov ah, al
    or al, 03h
    out 61h, al
    mov cx, 2000h
    call delay_custom
    mov al, ah
    out 61h, al
    pop dx
    pop cx
    pop bx
    pop ax
    ret

delay_custom:
.dloop:
    nop
    nop
    loop .dloop
    ret

sound_paddle:
    mov di, 440
    call play_sound
    ret

sound_brick:
    mov di, 1000
    call play_sound
    ret

sound_loss:
    mov di, 100
    call play_sound
    ret

; ------------------------------------------------------------------------------

draw_bricks:
    mov cx, BRICK_ROWS
    mov dx, START_Y
    mov bx, 0           ; Index into brick_array
.row_loop:
    push cx
    push dx
    
    mov cx, BRICK_COLS
    mov si, START_X     ; SI = Screen X position
    
.col_loop:
    cmp byte [brick_array + bx], 0
    je .skip_brick
    
    ; Found a brick. Draw it.
    push bx             ; Save Index
    push cx             ; Save Col Counter
    push si             ; Save Screen X
    push dx             ; Save Screen Y
    
    ; Determine Color
    mov al, [brick_array + bx]
    xor ah, ah
    
    ; Map Type to Color
    mov di, ax          ; Default to Type as Color
    cmp al, 3
    je .red
    cmp al, 4
    je .yellow
    jmp .set_color
.red:
    mov di, 4
    jmp .set_color
.yellow:
    mov di, 14
.set_color:
    
    ; Setup for draw_brick
    mov bx, si          ; BX = X position
    mov si, di          ; SI = Color
    ; DX is already Y position
    
    call draw_brick
    
    pop dx
    pop si
    pop cx
    pop bx

.skip_brick:
    inc bx
    add si, BRICK_WIDTH + BRICK_GAP
    loop .col_loop
    
    pop dx
    add dx, BRICK_HEIGHT + BRICK_GAP
    pop cx
    loop .row_loop
    ret

draw_brick:
    push ax
    push cx
    push di
    push es
    
    ; Ensure ES points to video memory
    mov ax, 0A000h
    mov es, ax
    
    mov cx, BRICK_HEIGHT
.brick_y_loop:
    push cx
    push dx
    mov ax, 320
    mul dx
    add ax, bx
    mov di, ax
    mov cx, BRICK_WIDTH
    mov ax, si
    rep stosb
    pop dx
    inc dx
    pop cx
    loop .brick_y_loop
    
    pop es
    pop di
    pop cx
    pop ax
    ret

erase_brick:
    ; Input: SI = X position, DX = Y position
    ; Erase a BRICK_WIDTH x BRICK_HEIGHT rectangle
    
    push ax
    push bx
    push cx
    push dx
    push di
    push si
    push es
    
    ; Set ES to video memory
    ; Set ES to video memory
    mov ax, 0A000h
    mov es, ax
    
    ; Adjust start position to be safe (1 pixel left/up)
    ; dec si
    ; dec dx
    
    ; Erase slightly larger area
    ; mov bx, BRICK_HEIGHT + 2
    mov bx, BRICK_HEIGHT
    
.eb_row_loop:
    ; Calculate video memory offset for this row
    mov ax, dx          ; AX = Y
    mov cx, 320
    mul cx              ; AX = Y * 320
    add ax, si          ; AX = Y * 320 + X
    mov di, ax          ; DI = offset
    
    ; Inner loop: BRICK_WIDTH pixels
    mov cx, BRICK_WIDTH
    xor al, al          ; Black pixel
.eb_col_loop:
    stosb               ; Write black pixel at ES:DI, increment DI
    loop .eb_col_loop
    
    ; Move to next row
    inc dx
    dec bx
    jnz .eb_row_loop
    
    pop es
    pop si
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_paddle:
    mov bx, [paddle_x]
    mov dx, PADDLE_Y
    mov si, PADDLE_COLOR
    call draw_rect_paddle
    ret

clear_paddle:
    mov bx, [paddle_x]
    mov dx, PADDLE_Y
    mov si, 0
    call draw_rect_paddle
    ret

draw_rect_paddle:
    push ax
    push cx
    push di
    push es
    
    ; Ensure ES points to video memory
    mov ax, 0A000h
    mov es, ax
    
    mov cx, PADDLE_HEIGHT
.drp_loop:
    push cx
    push dx
    mov ax, 320
    mul dx
    add ax, bx
    mov di, ax
    mov cx, PADDLE_WIDTH
    mov ax, si
    rep stosb
    pop dx
    inc dx
    pop cx
    loop .drp_loop
    
    pop es
    pop di
    pop cx
    pop ax
    ret

draw_ball:
    mov bx, [ball_x]
    mov dx, [ball_y]
    mov si, BALL_COLOR
    call draw_rect_ball
    ret

clear_ball:
    mov bx, [ball_x]
    mov dx, [ball_y]
    mov si, 0
    call draw_rect_ball
    ret

draw_rect_ball:
    push ax
    push cx
    push di
    push es
    
    ; Ensure ES points to video memory
    mov ax, 0A000h
    mov es, ax
    
    mov cx, BALL_SIZE
.drb_loop:
    push cx
    push dx
    mov ax, 320
    mul dx
    add ax, bx
    mov di, ax
    mov cx, BALL_SIZE
    mov ax, si
    rep stosb
    pop dx
    inc dx
    pop cx
    loop .drb_loop
    
    pop es
    pop di
    pop cx
    pop ax
    ret

update_ball:
    mov ax, [ball_x]
    add ax, [ball_vel_x]
    mov [ball_x], ax
    mov ax, [ball_y]
    add ax, [ball_vel_y]
    mov [ball_y], ax
    call check_wall_collision
    call check_paddle_collision
    call check_brick_collision
    ret

check_wall_collision:
    cmp word [ball_x], 0
    jg .check_right
    mov word [ball_vel_x], 2
.check_right:
    cmp word [ball_x], SCREEN_WIDTH - BALL_SIZE
    jl .check_top
    mov word [ball_vel_x], -2
.check_top:
    cmp word [ball_y], 0
    jg .check_bottom
    mov word [ball_vel_y], 2
.check_bottom:
    cmp word [ball_y], SCREEN_HEIGHT - BALL_SIZE
    jl .done_walls
    call lose_life
.done_walls:
    ret

check_paddle_collision:
    mov ax, [ball_y]
    add ax, BALL_SIZE
    cmp ax, PADDLE_Y
    jl .no_paddle_hit
    mov ax, [ball_y]
    cmp ax, PADDLE_Y + PADDLE_HEIGHT
    jg .no_paddle_hit
    mov ax, [ball_x]
    add ax, BALL_SIZE
    cmp ax, [paddle_x]
    jl .no_paddle_hit
    mov ax, [ball_x]
    mov bx, [paddle_x]
    add bx, PADDLE_WIDTH
    cmp ax, bx
    jg .no_paddle_hit
    
    call sound_paddle
    mov word [ball_vel_y], -2
    mov ax, [ball_x]
    add ax, BALL_SIZE/2
    mov bx, [paddle_x]
    add bx, PADDLE_WIDTH/2
    cmp ax, bx
    jl .hit_left
    mov word [ball_vel_x], 2
    jmp .no_paddle_hit
.hit_left:
    mov word [ball_vel_x], -2
.no_paddle_hit:
    ret

check_brick_collision:
    ; Determine Y coordinate to check based on direction
    mov ax, [ball_y]
    cmp word [ball_vel_y], 0
    jl .check_y_top     ; Moving UP: Check top edge (ball_y)
    add ax, BALL_SIZE   ; Moving DOWN: Check bottom edge
.check_y_top:

    cmp ax, START_Y + BRICK_ROWS * (BRICK_HEIGHT + BRICK_GAP)
    jle .check_y_min
    jmp .no_brick_hit

.check_y_min:
    cmp ax, START_Y
    jge .calc_row
    jmp .no_brick_hit

.calc_row:
    sub ax, START_Y
    mov cl, BRICK_HEIGHT + BRICK_GAP
    div cl
    
    ; Check if in vertical gap
    ; Check if in vertical gap
    cmp ah, BRICK_HEIGHT
    jl .check_vertical_ok
    jmp .no_brick_hit   ; Hit in the gap!
.check_vertical_ok:
    
    xor ah, ah
    mov bx, ax          ; BX = Row index
    
    ; Determine X coordinate to check based on direction
    mov ax, [ball_x]
    cmp word [ball_vel_x], 0
    jl .check_x_left    ; Moving LEFT: Check left edge (ball_x)
    add ax, BALL_SIZE   ; Moving RIGHT: Check right edge
.check_x_left:

    sub ax, START_X
    cmp ax, 0
    jge .calc_col
    jmp .no_brick_hit

.calc_col:
    mov cl, BRICK_WIDTH + BRICK_GAP
    div cl
    
    ; Check if in horizontal gap
    cmp ah, BRICK_WIDTH
    jl .check_horizontal_ok
    jmp .no_brick_hit   ; Hit in the gap!
.check_horizontal_ok:
    
    xor ah, ah
    mov si, ax          ; SI = Col index
    
    cmp bx, BRICK_ROWS
    jl .check_cols
    jmp .no_brick_hit

.check_cols:
    cmp si, BRICK_COLS
    jl .calc_index
    jmp .no_brick_hit

.calc_index:
    mov ax, bx
    mov cx, BRICK_COLS
    mul cx
    add ax, si
    mov di, ax
    
    cmp byte [brick_array + di], 0
    jne .hit_brick
    jmp .no_brick_hit

.hit_brick:
    
    ; HIT!
    ; Save DI (brick index) before sound call corrupts it
    push di
    call sound_brick
    pop di
    
    ; Get Type for Score
    mov al, [brick_array + di]
    xor ah, ah
    mov cx, 10
    mul cx              ; Score = Type * 10
    
    ; CRITICAL: Save BX (row) and SI (col) before update_score corrupts them!
    push bx
    push si
    call update_score   ; Add AX to score (corrupts BX, SI via draw_status)
    pop si
    pop bx
    
    mov byte [brick_array + di], 0
    dec word [bricks_remaining]
    
    ; ROBUST: Use Pre-calculated Offset
    ; DI has the Brick Index (0-31)
    
    push bx
    mov bx, di
    shl bx, 1           ; Index * 2
    mov di, [brick_offsets + bx] ; DI = Video Memory Offset
    pop bx
    
    call erase_brick_direct
    
    neg word [ball_vel_y]
    
    cmp word [bricks_remaining], 0
    je next_level       ; Next Level instead of Win
    
.no_brick_hit:
    ret

erase_brick_direct:
    ; Input: DI = Video Memory Offset (0xA000:DI)
    ; Erase a BRICK_WIDTH x BRICK_HEIGHT rectangle
    
    push ax
    push bx
    push cx
    push di
    push es
    
    ; Set ES to video memory
    mov ax, 0A000h
    mov es, ax
    
    mov bx, BRICK_HEIGHT
.ebd_row_loop:
    push di             ; Save start of row
    
    mov cx, BRICK_WIDTH
    xor al, al          ; Black pixel
    rep stosb           ; Write black pixels
    
    pop di              ; Restore start of row
    add di, 320         ; Move to next line
    
    dec bx
    jnz .ebd_row_loop
    
    pop es
    pop di
    pop cx
    pop bx
    pop ax
    ret

check_input:
    mov ah, 01h
    int 16h
    jz .no_key
    mov ah, 00h
    int 16h
    cmp al, 1Bh
    je .exit_game
    cmp ah, 4Bh
    je .move_left
    cmp ah, 4Dh
    je .move_right
    jmp .no_key
.move_left:
    call clear_paddle
    mov ax, [paddle_x]
    sub ax, PADDLE_SPEED
    cmp ax, 0
    jge .update_x_left
    mov ax, 0
.update_x_left:
    mov [paddle_x], ax
    call draw_paddle
    jmp .no_key
.move_right:
    call clear_paddle
    mov ax, [paddle_x]
    add ax, PADDLE_SPEED
    mov bx, SCREEN_WIDTH - PADDLE_WIDTH
    cmp ax, bx
    jle .update_x_right
    mov ax, bx
.update_x_right:
    mov [paddle_x], ax
    call draw_paddle
    jmp .no_key
.exit_game:
    pop ax
    jmp exit_label
.no_key:
    ret

delay:
    ; Nested loop for delay
    ; Outer loop: 2 times
    ; Inner loop: 65535 times
    ; Total: ~130,000 instructions
    ; At 3 MIPS (DOSBox default-ish), this is ~40ms (25 FPS)
    
    mov cx, 2
.outer:
    push cx
    mov cx, 0FFFFh
.inner:
    nop
    loop .inner
    pop cx
    loop .outer
    ret

show_welcome:
    call clear_screen
    mov bp, title_msg
    mov cx, title_len
    mov dh, 8
    mov dl, 12
    mov bl, 0Fh
    call draw_text
    mov bp, rules_msg
    mov cx, rules_len
    mov dh, 12
    mov dl, 7
    mov bl, 07h
    call draw_text
    mov bp, controls_msg
    mov cx, controls_len
    mov dh, 14
    mov dl, 8
    mov bl, 07h
    call draw_text
    ret

draw_text:
    push es
    push ds
    pop es
    mov ax, 1300h
    mov bh, 0
    int 10h
    pop es
    ret

wait_for_menu_input:
.loop:
    mov ah, 00h
    int 16h
    cmp al, 0Dh
    je .start_game
    cmp al, 1Bh
    je .exit_game
    jmp .loop
.start_game:
    ret
.exit_game:
    pop ax
    jmp exit_label

wait_for_key:
    mov ah, 00h
    int 16h
    ret

exit_program:
    mov ah, 4Ch
    int 21h

section .data

SCREEN_WIDTH    equ 320
SCREEN_HEIGHT   equ 200

BRICK_WIDTH     equ 30
BRICK_HEIGHT    equ 10
BRICK_GAP       equ 5
BRICK_ROWS      equ 4
BRICK_COLS      equ 8
TOTAL_BRICKS    equ BRICK_ROWS * BRICK_COLS
START_X         equ 20
START_Y         equ 30
BRICK_COLOR     equ 4

PADDLE_WIDTH    equ 40
PADDLE_HEIGHT   equ 5
PADDLE_Y        equ 180
PADDLE_SPEED    equ 5
PADDLE_COLOR    equ 1
START_PADDLE_X  equ (SCREEN_WIDTH - PADDLE_WIDTH) / 2

BALL_SIZE       equ 4
BALL_COLOR      equ 15
START_BALL_X    equ 160
START_BALL_Y    equ 100
START_SPEED     equ 04FFFh

title_msg       db 'BRICK BREAKER'
title_len       equ $ - title_msg
rules_msg       db 'Destroy all bricks to win!'
rules_len       equ $ - rules_msg
controls_msg    db 'ENTER: Start   ESC: Quit'
controls_len    equ $ - controls_msg

score_msg       db 'Score: '
score_len       equ $ - score_msg
lives_msg       db 'Lives: '
lives_len       equ $ - lives_msg
level_msg       db 'Lvl: '
level_len       equ $ - level_msg
hi_msg          db 'HI: '
hi_len          equ $ - hi_msg

win_msg         db 'YOU WIN!'
win_len         equ $ - win_msg
lose_msg        db 'GAME OVER'
lose_len        equ $ - lose_msg
restart_msg     db 'Press Y to Restart, N to Quit'
restart_len     equ $ - restart_msg

filename        db 'hiscore.dat', 0

section .bss
brick_array     resb TOTAL_BRICKS
brick_offsets   resw TOTAL_BRICKS   ; Pre-calculated video offsets
paddle_x        resw 1
ball_x          resw 1
ball_y          resw 1
ball_vel_x      resw 1
ball_vel_y      resw 1

score           resw 1
lives           resw 1
level           resw 1
high_score      resw 1
game_speed      resw 1
bricks_remaining resw 1
