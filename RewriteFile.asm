.386

data segment use16
    file_invite_1 db 0Dh, 0Ah, 'Enter the file path for read: $'
    file_invite_2 db 0Dh, 0Ah, 'Enter the file path for write: $'
    success db 0Dh, 0Ah, 'Transport bytes successfully!$'
    
    error_open db 0Dh, 0Ah, 'Can not open the file or file did not exists!$'
    error_create db 0Dh, 0Ah, 'Can not create new file!$'
    error_read db 0Dh, 0Ah, 'Can not read data from file!$'
    error_write db 0Dh, 0Ah, 'Can not write data into file!$'
    error_empty db 0Dh, 0Ah, 'Empty file!$'
    error_position db 0Dh, 0Ah, 'Can not change file position!$'
    
    start_file_path db 101, 102 dup (0)
    handle_start dw ?
    
    finish_file_path db 101, 102 dup (0)
    handle_finish dw ?
    
    transport_byte db ?
    transport_values db 4 dup (0), 0Dh, 0Ah
data ends

procedures segment use16
assume cs:procedures, ds:data

file_open PROC
    mov bx, 0
    mov bl, [si + 1]
    mov byte ptr [si + bx + 2], 0
    
    mov ax, 3D00h
    lea dx, [si + 2]
    int 21h
    jc short open_error
    mov [bp], ax
    mov dx, 0
    jmp short return_ofr
    
open_error:
    lea dx, error_open
    
return_ofr:
    retf
    
file_open ENDP

create_file PROC
    mov bx, 0
    mov bl, [si + 1]
    mov byte ptr [si + bx + 2], 0
    
    mov cx, 0
    lea dx, [si + 2]
    mov ah, 3Ch
    int 21h
    jc short create_error
    mov [bp], ax
    mov dx, 0
    jmp short return_cf
    
create_error:
    lea dx, error_create
    
return_cf:
    retf

create_file ENDP

procedures ends

code segment use16
assume cs:code, ds:data
s1:
    mov ax, data
    mov ds, ax
    
welcome_open:
    mov ah, 09h
    lea dx, file_invite_1
    int 21h
    
    mov ah, 0Ah
    lea dx, start_file_path
    int 21h
    
    lea si, start_file_path
    lea bp, handle_start
    
    call far ptr procedures:file_open
    cmp dx, 0
    jnz print_error_r
    
welcome_create:
    mov ah, 09h
    lea dx, file_invite_2
    int 21h
    
    mov ah, 0Ah
    lea dx, finish_file_path
    int 21h
    
    lea si, finish_file_path
    lea bp, handle_finish
    
    call far ptr procedures:create_file
    cmp dx, 0
    jnz short print_error_w
    
    mov si, 0
    mov bx, handle_start
transport_loop:
    mov ah, 3Fh
    mov cx, 1
    lea dx, transport_byte
    int 21h
    jc short print_error_read
    
    cmp ax, 00h
    jz short zero_file
    inc si
    cmp byte ptr transport_byte, 0Dh
    jnz short transport_loop
    
    mov ax, 4201h
    mov dx, 0FFFBh
    mov cx, 0FFFFh
    int 21h
    jc short print_error_position
    mov bp, 0

four_loop:
    mov ah, 3Fh
    mov cx, 1
    lea dx, [transport_values + bp]
    int 21h
    jc short print_error_read
    inc bp
    cmp bp, 4
    jnz short four_loop
    
    mov ah, 40h
    mov bx, handle_finish
    lea dx, transport_values
    mov cx, 6
    int 21h
    jc short print_error_write
    
    mov bx, handle_start
    mov ax, 4201h
    mov dx, 0002h
    mov cx, 0000h
    int 21h
    jc short print_error_position
    jmp short transport_loop
    
print_error_r:
    mov ah, 09h
    int 21h
    jmp welcome_open
    
print_error_w:
    mov ah, 09h
    int 21h
    jmp welcome_create
    
print_error_read:
    mov ah, 09h
    lea dx, error_read
    int 21h
    jmp welcome_open
    
print_error_write:
    mov ah, 09h
    lea dx, error_write
    int 21h
    jmp welcome_create
    
print_error_position:
    mov ah, 09h
    lea dx, error_position
    int 21h
    jmp short end_work
    
zero_file:
    cmp si, 0
    jnz short success_out
    lea dx, error_empty
    jmp short print_error_r
    
success_out:
    mov ah, 09h
    lea dx, success
    int 21h
    jmp short end_work
    
end_work:
    mov ah, 3Eh
    mov bx, handle_start
    int 21h
    mov bx, handle_finish
    int 21h
    
    mov ah, 4Ch
    int 21h
    
code ends
end s1
