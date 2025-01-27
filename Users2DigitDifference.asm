.386

data segment use16
    invite_dec db 0Dh, 0Ah, 'Write the DEC signed digit from -32768 to +32767 with sign: $'
    invite_hex db 0Dh, 0Ah, 'Write the HEX signed 2-bytes digit: $'
    result db 0Dh, 0Ah, 'Difference between digits =$'
    
    sign_error db 0Dh, 0Ah, 'You did not enter the sign!$'
    upper_2bytes db 0Dh, 0Ah, 'The signed digit is greater than 2 bytes!$'
    non_format db 0Dh, 0Ah, 'Invalid format!$'
    
    f_dec_buffer db 7, 8 dup (0)
    f_hex_buffer db 5, 6 dup (0)
    
    dec_digit dd ?
    binary_res dd 40 dup (0), '$'
data ends

procedures segment use16
assume cs:procedures, ds:data

dec_convert PROC
    mov dx, 0
    mov eax, 0
    mov si, 3
    
    cmp byte ptr [bp + 2], 2Bh
    jnz short check_minus
    jmp short convert_loop
    
check_minus:
    cmp byte ptr [bp + 2], 2Dh
    jnz short error_sign

convert_loop:
    mov cl, [bp + si]
    cmp cl, 0Dh
    jz short level_digit
    cmp cl, '0'
    jl short error_format
    cmp cl, '9'
    jg short error_format
    sub cl, '0'
    movzx cx, cl
    imul ax, 10
    jc short error_size
    add ax, cx
    inc si
    jmp short convert_loop
    
level_digit:
    cmp byte ptr [bp + 2], 2Dh
    jz short reverse
    cmp eax, 7FFFh
    jg short error_size
    jmp short return_fd
 
reverse:
    cmp eax, 8000h
    jg short error_size
    neg ax
    jmp short return_fd
    
error_sign:
    lea dx, sign_error
    jmp short return_fd
    
error_format:
    lea dx, non_format
    jmp short return_fd
    
error_size:
    lea dx, upper_2bytes
    
return_fd:
    movsx eax, ax
    retf
dec_convert ENDP

hex_converter PROC
    mov dx, 0
    mov ax, 0
    mov si, 2
    mov cx, 4
    
convert_loop_s:
    mov bl, byte ptr [bp + si]
    cmp bl, 0Dh
    je short return_sd_s

    cmp bl, '0'                  
    jl short error_format_s      
    cmp bl, '9'
    jg short check_alpha_upper_s 

    sub bl, '0'                  
    jmp short add_digit_s

check_alpha_upper_s:
    cmp bl, 'A'                 
    jl short error_format_s 
    cmp bl, 'F'
    jg short check_alpha_lower_s      
    sub bl, 'A'                 
    add bl, 10
    jmp short add_digit_s

check_alpha_lower_s:
    cmp bl, 'a'                  
    jl short error_format_s     
    cmp bl, 'f'
    jg short error_format_s     
    sub bl, 'a'                  
    add bl, 10

add_digit_s:
    shl ax, 4                    
    or al, bl                    
    inc si                      
    loop convert_loop_s          
    jmp short return_sd_s
    
error_format_s:
    lea dx, non_format
    
return_sd_s:
    movsx eax, ax
    retf

hex_converter ENDP

binary_convert PROC
    mov bx, 0
    mov dl, 4
    mov cx, 32

main_loop:
    mov ax, cx
    div dl
    cmp ah, 0
    jnz short add_any
    mov byte ptr [si + bx], 20h
    inc bx
 
add_any:   
    shl ebp, 1
    jc short add_one
    mov byte ptr [si + bx], '0'
    inc bx
    jmp short countinue
    
add_one:
    mov byte ptr [si + bx], '1'
    inc bx
    jmp short countinue
    
countinue:
    loop main_loop
    
    retf
binary_convert ENDP

procedures ends

code segment use16
assume cs:code, ds:data
s1:
    mov ax, data
    mov ds, ax
    
welcome_dec:
    mov ah, 09h
    lea dx, invite_dec
    int 21h
    
    mov ah, 0Ah
    lea dx, f_dec_buffer
    int 21h
    
    lea bp, f_dec_buffer
    
    call far ptr procedures:dec_convert
    cmp dx, 0
    jnz short print_error_d
    mov ds:dec_digit, eax
    
welcome_hex:
    mov ah, 09h
    lea dx, invite_hex
    int 21h
    
    mov ah, 0Ah
    lea dx, f_hex_buffer
    int 21h
    
    lea bp, f_hex_buffer
    
    call far ptr procedures:hex_converter
    cmp dx, 0
    jnz short print_error_h
    
    mov ebp, dec_digit
    lea si, binary_res
    
    sub ebp, eax
    
to_2_convert:
    call far ptr procedures:binary_convert
    
    mov ah, 09h
    lea dx, result
    int 21h
    
    mov ah, 09h
    lea dx, binary_res
    int 21h
    jmp short end_work

print_error_d:
    mov ah, 09h
    int 21h
    jmp short welcome_dec
    
print_error_h:
    mov ah, 09h
    int 21h
    jmp short welcome_hex
    
end_work:
    mov ah, 4Ch
    int 21h
code ends
end s1