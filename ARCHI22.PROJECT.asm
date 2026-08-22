;=============================================================================
; PROJECT   : Epsilon Calculator
; LANGUAGE  : x86 Assembly (8086, real mode, DOS)
; AUTHOR    : Epsilon
; PLATFORM  : MS-DOS / DOSBox (assemble with MASM or TASM)
;
; DESCRIPTION
;   A menu-driven command-line calculator supporting four number systems
;   (decimal, binary, octal, hexadecimal) and two families of operations:
;
;     Arithmetic : Addition, Subtraction, Multiplication, Division, Power
;     Bitwise    : AND, OR, XOR, NOT, Shift-Left, Shift-Right
;
; FEATURES
;   - Signed decimal input/output (negative numbers supported)
;   - Full input validation per number system, with audible error feedback
;   - Overflow detection on every arithmetic operation
;   - Division by zero protection, with quotient AND remainder displayed
;   - Exponent / shift-count range validation
;   - Repeat loop: perform multiple calculations without restarting
;   - Reusable, documented procedures (no code duplication)
;
; BUILD (TASM example)
;   TASM calculator.asm
;   TLINK  calculator.obj
;   calculator.exe
;=============================================================================

.model medium
.stack 200h                    ; 512-byte stack

;=============================================================================
; CONSTANTS
;=============================================================================
BUFFER_SIZE     EQU 20         ; size of the number-conversion scratch buffer
MAX_SHIFT       EQU 15         ; maximum allowed shift count for a 16-bit word

;=============================================================================
; DATA SEGMENT
;=============================================================================
.data

; ---- Banners -----------------------------------------------------------
welcome_msg     DB "  ------------------------------------------- ", 0Dh, 0Ah
                DB "  |        EPSILON CALCULATOR (8086)         | ", 0Dh, 0Ah
                DB "  |  Decimal * Binary * Octal * Hexadecimal  | ", 0Dh, 0Ah
                DB "  ------------------------------------------- ", 0Dh, 0Ah, 0Dh, 0Ah, '$'

end_msg         DB 0Dh, 0Ah, "  ------------------------------------------- ", 0Dh, 0Ah
                DB "     Thank you for using Epsilon Calculator   ", 0Dh, 0Ah
                DB "  ------------------------------------------- ", 0Dh, 0Ah, '$'

; ---- Number system menu -------------------------------------------------
select_system_msg DB 0Dh, 0Ah, "Select number system:", 0Dh, 0Ah
                   DB "----------------------", 0Dh, 0Ah
                   DB "  1. Decimal        3. Octal", 0Dh, 0Ah
                   DB "  2. Binary         4. Hexadecimal", 0Dh, 0Ah
                   DB "Choice: $"

; ---- Operation menu ------------------------------------------------------
select_operation_msg DB 0Dh, 0Ah, "Select operation:", 0Dh, 0Ah
                     DB "------------------", 0Dh, 0Ah
                     DB "  Arithmetic:                 Bitwise:", 0Dh, 0Ah
                     DB "   +  Addition                 &  AND", 0Dh, 0Ah
                     DB "   -  Subtraction               |  OR", 0Dh, 0Ah
                     DB "   *  Multiplication            x  XOR", 0Dh, 0Ah
                     DB "   /  Division (quo. + rem.)    !  NOT      (unary)", 0Dh, 0Ah
                     DB "   ^  Power (A raised to B)     l  Shift Left", 0Dh, 0Ah
                     DB "                                r  Shift Right", 0Dh, 0Ah
                     DB "Choice: $"

; ---- Prompts --------------------------------------------------------------
input_a_msg     DB 0Dh, 0Ah, "Enter first  number  A = $"
input_b_msg     DB 0Dh, 0Ah, "Enter second number  B = $"
continue_msg    DB 0Dh, 0Ah, 0Dh, 0Ah, "Perform another calculation? (Y/N): $"

; ---- Result display fragments ---------------------------------------------
result_header   DB 0Dh, 0Ah, 0Dh, 0Ah, "  Result: $"
equals_msg      DB " = $"
remainder_msg   DB "   (Remainder: $"
close_paren_msg DB ")$"
newline_msg     DB 0Dh, 0Ah, '$'

; ---- Operator symbols used in result display -------------------------------
op_add_str      DB " + $"
op_sub_str      DB " - $"
op_mul_str      DB " * $"
op_div_str      DB " / $"
op_pow_str      DB " ^ $"
op_and_str      DB " AND $"
op_or_str       DB " OR $"
op_xor_str      DB " XOR $"
op_shl_str      DB " << $"
op_shr_str      DB " >> $"
op_not_prefix   DB "NOT $"

; ---- Error messages ---------------------------------------------------------
invalid_choice_msg   DB 0Dh, 0Ah, "Invalid choice! Please try again.", 0Dh, 0Ah, '$'
overflow_error_msg   DB 0Dh, 0Ah, "Error: arithmetic overflow.", 0Dh, 0Ah, '$'
div_zero_error_msg   DB 0Dh, 0Ah, "Error: division by zero.", 0Dh, 0Ah, '$'
bad_exponent_msg     DB 0Dh, 0Ah, "Error: exponent must be zero or positive.", 0Dh, 0Ah, '$'
bad_shift_msg        DB 0Dh, 0Ah, "Error: shift count must be between 0 and 15.", 0Dh, 0Ah, '$'

; ---- Working variables --------------------------------------------------
number_system   DB 1                    ; 1=dec 2=bin 3=oct 4=hex
a               DW 0                    ; first operand
b               DW 0                    ; second operand
result          DW 0                    ; operation result
remainder       DW 0                    ; remainder (division only)
is_negative     DB 0                    ; sign flag used while reading input
operation       DB '+'                  ; currently selected operation
op_str_offset   DW 0                    ; pointer to the operator string to print
temp_buffer     DB BUFFER_SIZE DUP (0)  ; scratch buffer for base conversion

;=============================================================================
; MACROS  (reduce repetition, improve readability)
;=============================================================================
PRINT_STR MACRO msg
    mov ah, 09h
    lea dx, msg
    int 21h
ENDM

PRINT_PTR MACRO ptr_var
    mov ah, 09h
    mov dx, ptr_var
    int 21h
ENDM

READ_CHAR MACRO
    mov ah, 01h
    int 21h
ENDM

;=============================================================================
; CODE SEGMENT
;=============================================================================
.code
main proc
    mov ax, @data
    mov ds, ax

    PRINT_STR welcome_msg

main_loop:
    ;-------------------------------------------------------------------
    ; STEP 1 - Choose number system
    ;-------------------------------------------------------------------
select_system_loop:
    PRINT_STR select_system_msg
    READ_CHAR
    cmp al, '1'
    jb  invalid_system
    cmp al, '4'
    ja  invalid_system
    sub al, '0'
    mov number_system, al
    jmp read_first_number

invalid_system:
    PRINT_STR invalid_choice_msg
    jmp select_system_loop

    ;-------------------------------------------------------------------
    ; STEP 2 - Read operand A (always required)
    ;-------------------------------------------------------------------
read_first_number:
    PRINT_STR input_a_msg
    call read_number
    mov a, bx

    ;-------------------------------------------------------------------
    ; STEP 3 - Choose operation
    ;-------------------------------------------------------------------
select_operation_loop:
    PRINT_STR select_operation_msg
    READ_CHAR
    or  al, 20h                 ; normalize letters (x/l/r) to lowercase
    mov operation, al

    cmp al, '+'
    je  need_b
    cmp al, '-'
    je  need_b
    cmp al, '*'
    je  need_b
    cmp al, '/'
    je  need_b
    cmp al, '^'
    je  need_b
    cmp al, '&'
    je  need_b
    cmp al, '|'
    je  need_b
    cmp al, 'x'
    je  need_b
    cmp al, 'l'
    je  need_b
    cmp al, 'r'
    je  need_b
    cmp al, '!'
    je  do_not                  ; unary: no need to read B

    PRINT_STR invalid_choice_msg
    jmp select_operation_loop

    ;-------------------------------------------------------------------
    ; STEP 4 - Read operand B (all operations except NOT)
    ;-------------------------------------------------------------------
need_b:
    PRINT_STR input_b_msg
    call read_number
    mov b, bx

    ; dispatch to the correct handler
    mov al, operation
    cmp al, '+'
    je  do_addition
    cmp al, '-'
    je  do_subtraction
    cmp al, '*'
    je  do_multiplication
    cmp al, '/'
    je  do_division
    cmp al, '^'
    je  do_power
    cmp al, '&'
    je  do_and
    cmp al, '|'
    je  do_or
    cmp al, 'x'
    je  do_xor
    cmp al, 'l'
    je  do_shift_left
    jmp do_shift_right

;=============================================================================
; OPERATION HANDLERS
;=============================================================================
do_addition:
    mov ax, a
    add ax, b
    jo  overflow_detected
    mov result, ax
    mov op_str_offset, offset op_add_str
    jmp show_binary_result

do_subtraction:
    mov ax, a
    sub ax, b
    jo  overflow_detected
    mov result, ax
    mov op_str_offset, offset op_sub_str
    jmp show_binary_result

do_multiplication:
    mov ax, a
    imul b
    jo  overflow_detected
    mov result, ax
    mov op_str_offset, offset op_mul_str
    jmp show_binary_result

do_division:
    cmp b, 0
    je  division_by_zero
    ; guard the classic INT_MIN / -1 overflow case
    cmp a, 8000h
    jne div_ok
    cmp b, -1
    je  overflow_detected
div_ok:
    mov ax, a
    cwd
    idiv b
    mov result, ax
    mov remainder, dx
    mov op_str_offset, offset op_div_str
    jmp show_division_result

do_power:
    cmp b, 0
    jl  bad_exponent
    mov cx, b
    mov ax, 1
    cmp cx, 0
    je  power_done
power_loop:
    imul a
    jo  overflow_detected
    loop power_loop
power_done:
    mov result, ax
    mov op_str_offset, offset op_pow_str
    jmp show_binary_result

do_and:
    mov ax, a
    and ax, b
    mov result, ax
    mov op_str_offset, offset op_and_str
    jmp show_binary_result

do_or:
    mov ax, a
    or  ax, b
    mov result, ax
    mov op_str_offset, offset op_or_str
    jmp show_binary_result

do_xor:
    mov ax, a
    xor ax, b
    mov result, ax
    mov op_str_offset, offset op_xor_str
    jmp show_binary_result

do_not:
    ; unary operation: operand B was never requested
    mov ax, a
    not ax
    mov result, ax
    call show_not_result
    jmp ask_continue

do_shift_left:
    cmp b, 0
    jl  bad_shift
    cmp b, MAX_SHIFT
    jg  bad_shift
    mov ax, a
    mov cl, byte ptr b
    shl ax, cl
    mov result, ax
    mov op_str_offset, offset op_shl_str
    jmp show_binary_result

do_shift_right:
    cmp b, 0
    jl  bad_shift
    cmp b, MAX_SHIFT
    jg  bad_shift
    mov ax, a
    mov cl, byte ptr b
    sar ax, cl                 ; arithmetic shift: preserves sign for negatives
    mov result, ax
    mov op_str_offset, offset op_shr_str
    jmp show_binary_result

;=============================================================================
; ERROR HANDLERS
;=============================================================================
overflow_detected:
    PRINT_STR overflow_error_msg
    jmp ask_continue

division_by_zero:
    PRINT_STR div_zero_error_msg
    jmp ask_continue

bad_exponent:
    PRINT_STR bad_exponent_msg
    jmp ask_continue

bad_shift:
    PRINT_STR bad_shift_msg
    jmp ask_continue

;=============================================================================
; RESULT DISPLAY
;=============================================================================
show_binary_result:
    PRINT_STR result_header
    mov bx, a
    call display_number
    PRINT_PTR op_str_offset
    mov bx, b
    call display_number
    PRINT_STR equals_msg
    mov bx, result
    call display_number
    jmp ask_continue

show_division_result:
    PRINT_STR result_header
    mov bx, a
    call display_number
    PRINT_PTR op_str_offset
    mov bx, b
    call display_number
    PRINT_STR equals_msg
    mov bx, result
    call display_number
    PRINT_STR remainder_msg
    mov bx, remainder
    call display_number
    PRINT_STR close_paren_msg
    jmp ask_continue

;=============================================================================
; ASK TO REPEAT
;=============================================================================
ask_continue:
    PRINT_STR continue_msg
    READ_CHAR
    or  al, 20h                 ; normalize to lowercase
    cmp al, 'y'
    je  main_loop
    jmp exit_program

;=============================================================================
; EXIT
;=============================================================================
exit_program:
    PRINT_STR end_msg
    mov ah, 4Ch
    int 21h
main endp

;=============================================================================
; PROCEDURE: show_not_result
; Displays the result of the unary NOT operation using a prefix style:
; "NOT A = result" (there is no second operand to show).
;=============================================================================
show_not_result proc
    PRINT_STR result_header
    PRINT_STR op_not_prefix
    mov bx, a
    call display_number
    PRINT_STR equals_msg
    mov bx, result
    call display_number
    ret
show_not_result endp

;=============================================================================
; PROCEDURE: read_number
; Reads a number from the keyboard, digit by digit, validating each digit
; against the currently selected number system. Only decimal input may be
; signed (leading '-').
;
; OUT : BX = the parsed value
;=============================================================================
read_number proc
    push ax
    push cx
    push dx
    push si

    mov bx, 0
    mov cl, number_system
    mov is_negative, 0

    cmp cl, 1                   ; only decimal supports a sign
    jne read_loop

    READ_CHAR
    cmp al, '-'
    jne not_negative
    mov is_negative, 1
    jmp read_next_char

not_negative:
    jmp process_digit

read_loop:
    READ_CHAR

read_next_char:
    cmp al, 13                  ; Enter key ends input
    je  end_read

process_digit:
    cmp al, '0'
    jb  invalid_digit
    cmp al, '9'
    jbe digit_0_9

    cmp cl, 4                   ; letters A-F are only valid in hex mode
    jne invalid_digit
    or  al, 20h
    cmp al, 'a'
    jb  invalid_digit
    cmp al, 'f'
    ja  invalid_digit
    sub al, 'a' - 10
    jmp add_digit

digit_0_9:
    sub al, '0'

add_digit:
    mov ch, al                  ; ch = numeric value of the digit

    cmp cl, 2                   ; binary: digit must be 0 or 1
    je  check_binary
    cmp cl, 3                   ; octal: digit must be 0-7
    je  check_octal
    jmp digit_valid             ; decimal/hex already validated above

check_binary:
    cmp ch, 1
    ja  invalid_digit
    jmp digit_valid

check_octal:
    cmp ch, 7
    ja  invalid_digit

digit_valid:
    push ax
    mov  ax, bx

    cmp cl, 1
    je  mul_10
    cmp cl, 2
    je  mul_2
    cmp cl, 3
    je  mul_8

    shl bx, 4                   ; hexadecimal: multiply by 16
    jmp add_new_digit

mul_10:
    mov cx, 10
    mul cx
    mov bx, ax
    jmp add_new_digit

mul_2:
    shl bx, 1
    jmp add_new_digit

mul_8:
    shl bx, 3

add_new_digit:
    pop ax
    mov cl, al
    mov ch, 0
    add bx, cx
    mov cl, number_system        ; restore cl (used as base selector)
    jmp read_loop

invalid_digit:
    mov ah, 02h                  ; audible feedback (BEL)
    mov dl, 07h
    int 21h
    jmp read_loop

end_read:
    cmp number_system, 1
    jne read_done
    cmp is_negative, 1
    jne read_done
    neg bx

read_done:
    pop si
    pop dx
    pop cx
    pop ax
    ret
read_number endp

;=============================================================================
; PROCEDURE: display_number
; Prints BX in the currently selected number system.
; Negative values are only meaningful (and only ever produced) in decimal.
;=============================================================================
display_number proc
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov cl, number_system
    mov ax, bx

    cmp cl, 1
    jne not_decimal_neg
    cmp ax, 0
    jge not_decimal_neg

    push ax
    mov ah, 02h
    mov dl, '-'
    int 21h
    pop ax
    neg ax

not_decimal_neg:
    lea di, temp_buffer
    add di, BUFFER_SIZE - 1
    mov byte ptr [di], '$'

    cmp ax, 0
    jne convert_loop
    mov byte ptr [di-1], '0'
    dec di
    jmp display_digits

convert_loop:
    mov dx, 0

    cmp cl, 1
    je  div_10
    cmp cl, 2
    je  div_2
    cmp cl, 3
    je  div_8

    mov cx, 16
    div cx
    jmp store_digit

div_10:
    mov cx, 10
    div cx
    jmp store_digit

div_2:
    mov cx, 2
    div cx
    jmp store_digit

div_8:
    mov cx, 8
    div cx

store_digit:
    cmp dl, 9
    jbe digit_0_9_disp
    add dl, 'A' - 10
    jmp store_char

digit_0_9_disp:
    add dl, '0'

store_char:
    dec di
    mov [di], dl
    mov cl, number_system        ; restore cl (used as base selector)
    cmp ax, 0
    jne convert_loop

display_digits:
    mov ah, 09h
    mov dx, di
    int 21h

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
display_number endp

end main
