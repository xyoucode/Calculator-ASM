; Calculator program in 8086 assembly 
; Decimal, binary, octal, and hexadecimal number systems
; The ability to perform operations on negative numbers
; Supports division with quotient and remainder display 
 ====================================================================================================
=============================================================================

.model medium   
.stack 200h     ; Stack size - 512 bytes (200h)

.data
                                                               
; Welcome message displayed at program start
welcome_msg DB  "               ------------------------------------ ", 0Dh, 0Ah 
            DB  "               |> Calculator Realized by Epsilon <| ", 0Dh, 0Ah
            DB  "               ------------------------------------ ", 0Dh, 0Ah, 0Dh, 0Ah, '$'  

; Menu for selecting number system (decimal, hex, binary, octal)
select_system   DB 0Dh, 0Ah, ".Select number system:", 0Dh, 0Ah  
                DB "----------------------", 0Dh, 0Ah 
                DB "  .Decimal <1>   .Octal       <3> " , 0Dh, 0Ah 
                DB "  .Binary  <2>   .Hexadecimal <4> " , 0Dh, 0Ah  
                DB "    Choice: $" 
                                     
; Messages for number input                   
input_a_msg  DB 0Dh, 0Ah,0Dh, 0Ah, '.Enter The first  Number A= $'
input_b_msg  DB 0Dh, 0Ah,          '.Enter The second Number B= $' 
 
; Menu for selecting arithmetic operation 
select_operation  DB 0Dh, 0Ah,0Dh, 0Ah, ".Select operation:", 0Dh, 0Ah
                  DB "------------------", 0Dh, 0Ah  
                  DB "  .Addition       <+>"   , 0Dh, 0Ah
                  DB "  .Subtraction    <->"   , 0Dh, 0Ah
                  DB "  .Multiplication <*>"   , 0Dh, 0Ah
                  DB "  .Division       </>"   , 0Dh, 0Ah 
                  DB "    Choice: $" 
             
; Messages for displaying results             
result_msg    DB 0Dh, 0Ah, 0Dh, 0Ah, '     | Result: $' 
equals_msg    DB ' = $'
remainder_msg DB ' mod: $'
newline       DB 0Dh, 0Ah, '$' 

; end message displayed at program end
end_msg      DB , 0Dh, 0Ah , "  -----------------------------------  " , 0Dh, 0Ah
             DB  "  <Thank you for using my calculator>  " , 0Dh, 0Ah, 0Dh, 0Ah , '$' 
    
; Error messages    
invalid_choice DB  'Invalid choice! Please try again.', 0Dh, 0Ah , '$'
overflow_error DB  'Error: Arithmetic overflow!'      , 0Dh, 0Ah , '$'
div_zero_error DB  'Error: Division by zero!'         , 0Dh, 0Ah , '$'
    
; Data variables
number_system db 1          ; Stores selected number system (1=dec, 2=bin, 3=oct, 4=hex)
a dw 0                      ; First operand
b dw 0                      ; Second operand
result dw 0                 ; Calculation result
remainder dw 0              ; Remainder for division
is_negative db 0            ; Flag for negative numbers
operation db ?              ; Stores selected operation (+,-,*,/)
temp_buffer db 20 dup (0)   ; Temporary buffer for number conversion

.code  
main proc
    mov ax, @data           ; Initialize data segment
    mov ds, ax
    
    ; Display welcome message
    mov ah, 09h             ; DOS function to display string
    lea dx, welcome_msg
    int 21h
    
select_system_loop:
    ; Display number system selection menu
    mov ah, 09h
    lea dx, select_system
    int 21h
    
    ; Get user input (1-4)
    mov ah, 01h             ; DOS function to read character
    int 21h
    
    ; Validate input (must be between '1' and '4')
    cmp al, '1'
    jb invalid_system
    cmp al, '4'
    ja invalid_system
    
    ; Convert ASCII to number and store
    sub al, '0'
    mov number_system, al
    jmp get_numbers
    
invalid_system:
    ; Show error for invalid number system selection
    mov ah, 09h
    lea dx, invalid_choice
    int 21h
    jmp select_system_loop
    
get_numbers:
    ; Get first number
    mov ah, 09h
    lea dx, input_a_msg
    int 21h
    call read_number        ; Call procedure to read number
    mov a, bx               ; Store result in variable 'a'
    
    ; Get second number
    mov ah, 09h
    lea dx, input_b_msg
    int 21h
    call read_number
    mov b, bx              ; Store result in variable 'b'
    
select_operation_loop:
    ; Display operation selection menu
    mov ah, 09h
    lea dx, select_operation
    int 21h
    
    ; Get operation choice
    mov ah, 01h
    int 21h
    mov operation, al      ; Store operation symbol
    
    ; Validate and jump to appropriate operation
    cmp al, '+'
    je do_addition
    cmp al, '-'
    je do_subtraction
    cmp al, '*'
    je do_multiplication
    cmp al, '/'
    je do_division
    
    ; Invalid operation selected
    mov ah, 09h
    lea dx, invalid_choice
    int 21h
    jmp select_operation_loop
    
do_addition:
    mov ax, a
    add ax, b              ; Add the two numbers
    jo overflow_detected   ; Jump if overflow occurred
    mov result, ax         ; Store result
    jmp display_result
    
do_subtraction:
    mov ax, a
    sub ax, b              ; Subtract b from a
    jo overflow_detected
    mov result, ax
    jmp display_result
    
do_multiplication:
    mov ax, a
    imul b                 ; Signed multiplication
    jo overflow_detected
    mov result, ax
    jmp display_result
    
do_division:
    mov ax, a
    cwd                    ; Convert word to doubleword (sign extend)
    mov bx, b
    cmp bx, 0              ; Check for division by zero
    je division_by_zero
    idiv bx                ; Signed division
    mov result, ax         ; Store quotient
    mov remainder, dx      ; Store remainder
    call display_division_result
    jmp exit_program
    
overflow_detected:
    ; Display overflow error message
    mov ah, 09h
    lea dx, overflow_error
    int 21h
    jmp exit_program
    
division_by_zero:
    ; Display division by zero error
    mov ah, 09h
    lea dx, div_zero_error
    int 21h
    jmp exit_program
    
display_result:
    ; Display result header
    mov ah, 09h
    lea dx, result_msg
    int 21h 
    
    ; Display first number (a)
    mov bx, a
    call display_number
    
    ; Display operation symbol
    mov ah, 02h            ; DOS function to display character
    mov dl, operation
    int 21h
    
    ; Display second number (b)
    mov bx, b
    call display_number
    
    ; Display equals sign
    mov ah, 09h
    lea dx, equals_msg
    int 21h
    
    ; Display result
    mov bx, result
    call display_number
    
    ; New line
    mov ah, 09h
    lea dx, newline
    int 21h  
    
    ; Display end message
    mov ah, 09h            ; DOS function to display string
    lea dx, end_msg
    int 21h
    
exit_program:
    ; Exit to DOS
    mov ah, 4ch
    int 21h
main endp

; Procedure to display division result with remainder
display_division_result proc
    ; Display result header
    mov ah, 09h
    lea dx, result_msg
    int 21h 
    
    ; Display first number (a)
    mov bx, a
    call display_number
    
    ; Display operation symbol
    mov ah, 02h
    mov dl, operation
    int 21h
    
    ; Display second number (b)
    mov bx, b
    call display_number
    
    ; Display equals sign
    mov ah, 09h
    lea dx, equals_msg
    int 21h
    
    ; Display quotient
    mov bx, result
    call display_number
    
    ; Display remainder
    mov ah, 09h
    lea dx, remainder_msg
    int 21h
    
    mov bx, remainder
    call display_number
    
    ; New line
    mov ah, 09h
    lea dx, newline
    int 21h
    
    ; Display end message
    mov ah, 09h
    lea dx, end_msg
    int 21h
    ret
display_division_result endp

; Procedure to read a number from user input
; Returns: BX = entered number
read_number proc
    push ax
    push cx
    push dx
    push si
    
    mov si, 0              ; Counter for digits
    mov bx, 0              ; Will hold the final number
    mov cl, number_system  ; Get current number system
    mov is_negative, 0     ; Reset negative flag
    
    ; Special handling for decimal (can be negative)
    cmp cl, 1
    jne read_loop
    
    mov ah, 01h
    int 21h
    cmp al, '-'
    jne not_negative
    
    mov is_negative, 1     ; Set negative flag
    jmp read_next_char
    
not_negative:
    jmp process_digit
    
read_loop:
    ; Read next character
    mov ah, 01h
    int 21h
    
read_next_char:
    cmp al, 13             ; Check for Enter key
    je end_read
    
process_digit:
    ; Validate digit based on number system
    cmp al, '0'
    jb invalid_digit
    cmp al, '9'
    jbe digit_0_9
    
    ; For hexadecimal only, accept A-F
    cmp cl, 4
    jne invalid_digit
    
    or al, 20h             ; Convert to lowercase
    cmp al, 'a'
    jb invalid_digit
    cmp al, 'f'
    ja invalid_digit
    sub al, 'a' - 10       ; Convert to value 10-15
    jmp add_digit
    
digit_0_9:
    sub al, '0'            ; Convert ASCII to value
    
add_digit:
    mov ch, al             ; Temporarily store digit
    ; Additional validation based on number system
    cmp cl, 2              ; Binary?
    je check_binary
    cmp cl, 3              ; Octal?
    je check_octal
    cmp cl, 4
    jmp digit_valid
    
check_binary:
    cmp ch, 1              ; Binary digit must be 0 or 1
    ja invalid_digit
    jmp digit_valid
    
check_octal:
    cmp ch, 7              ; Octal digit must be 0-7
    ja invalid_digit
    jmp digit_valid
    
invalid_digit:
    ; Beep on invalid digit
    mov ah, 02h
    mov dl, 07h
    int 21h
    jmp read_loop
    
digit_valid:
    push ax
    
    mov ax, bx
    
    ; Multiply current value by base (10, 2, 8, or 16)
    cmp cl, 1
    je mul_10
    cmp cl, 2
    je mul_2
    cmp cl, 3
    je mul_8
    
    shl bx, 4              ; For hex, multiply by 16
    jmp add_new_digit
    
mul_10:
    mov cx, 10
    mul cx
    mov bx, ax
    jmp add_new_digit
    
mul_2:
    shl bx, 1              ; Multiply by 2
    jmp add_new_digit
    
mul_8:
    shl bx, 3              ; Multiply by 8
    
add_new_digit:
    pop ax
    mov cl, al
    mov ch, 0
    add bx, cx             ; Add new digit
    
    inc si                 ; Increment digit counter
    jmp read_loop
    
end_read:
    ; For decimal numbers, handle negative sign
    cmp number_system, 1
    jne read_done
    
    cmp is_negative, 1
    jne read_done
    
    neg bx                 ; Negate the number
    
read_done:
    pop si
    pop dx
    pop cx
    pop ax
    ret
read_number endp

; Procedure to display a number in the selected base
; Input: BX = number to display
display_number proc
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    mov cl, number_system  ; Get current number system
    mov ax, bx             ; Work with AX
    
    ; Handle negative numbers for decimal only
    cmp cl, 1
    jne not_decimal_neg
    
    cmp ax, 0
    jge not_decimal_neg
    
    ; Display minus sign for negative decimal numbers
    push ax
    mov ah, 02h
    mov dl, '-'
    int 21h
    pop ax
    neg ax                 ; Work with absolute value
    
not_decimal_neg:
    ; Prepare buffer for digit conversion (store digits in reverse)
    lea di, temp_buffer
    add di, 19             ; Point to end of buffer
    mov byte ptr [di], '$' ; String terminator
    
    ; Handle zero case
    cmp ax, 0
    jne convert_loop
    
    mov byte ptr [di-1], '0'
    dec di
    jmp display_digits
    
convert_loop:
    mov dx, 0              ; Clear upper part for division
    
    ; Divide by base (10, 2, 8, or 16)
    cmp cl, 1
    je div_10
    cmp cl, 2
    je div_2
    cmp cl, 3
    je div_8
    
    mov cx, 16             ; For hex, divide by 16
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
    ; Convert remainder to ASCII character
    cmp dl, 9
    jbe digit_0_9_disp
    add dl, 'A' - 10       ; For hex digits A-F
    jmp store_char
    
digit_0_9_disp:
    add dl, '0'            ; For digits 0-9
    
store_char:
    dec di                 ; Move back in buffer
    mov [di], dl           ; Store ASCII digit
    
    cmp ax, 0              ; Continue until quotient is zero
    jne convert_loop
    
display_digits:
    ; Display the converted number
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