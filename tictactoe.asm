assume cs:code,ds:data

data segment
    welcomeMsg db "*************** Welcome to TicTacToeASM ***************",10,10,'$'
    gameOverMsg db "Game over!","$"
    player1WinMsg db "Player 1 wins!","$"
    player2WinMsg db "Player 2 wins!","$"
    currentPlayerMsg db "Current player: ","$"
    player1Msg db "Player 1",10,"$"
    player2Msg db "Player 2",10,"$"

    grid db 9 dup(0) ; 0 means that the cell isn't taken
    gridLength equ $-grid
    player1Symbol db 'X','$'
    player2Symbol db 'O','$'

    columnMsg db "column=","$"
    rowMsg db "row=","$"

    currentPlayer db 1 ; can take values from [1,2]

    separator db '|','$'
    blank db '*','$'
    newLine db 10,'$'
    enterCode db 0Dh
    delimiter db ' '

    buffer db 100 dup(0)
data ends

code segment
    ; Functions are defined here 

    ; void PrintString(char *str);
    ; The string must end with '$'.
    PrintString PROC NEAR
        push bp 
        mov bp,sp
        
        ; we will be using DX so we have to push it onto the stack
        push dx
        ; we will also be using AH(so we will push AX onto the stack)
        push ax
        push cx
        ; dx has to contain the address of the string to be printed
        mov dx,[bp + 4]
        ; we will be using serive 09h to print a string
        mov ah,09h
        ; call the intrerrupt
        int 21h

        pop cx
        pop ax
        pop dx
        pop bp

        ret 2 ; we have only accepted a param
    PrintString ENDP

    ; void DrawGrid(char *grid,int gridLength);
    ; The function assumes that the address of the grid and the grid length are pushed onto the stack.
    DrawGrid PROC NEAR
        push bp
        mov bp,sp

        push dx 
        push cx
        push ax
        push bx
        push di

        mov di,[bp + 4] ; di will contain the offset of the grid 
        mov cx,gridLength

        print_values:
            push offset separator
            call PrintString
            
            cmp byte ptr [di],0
            je print_not_taken
            cmp byte ptr [di],1
            je print_player1
            cmp byte ptr [di],2
            je print_player2

            ; print player2 symbol
            print_player2:
                push offset player2Symbol
                call PrintString
                jmp check_print_new_line
            
            ; print player1 symbol
            print_player1:
                push offset player1Symbol
                call PrintString
                jmp check_print_new_line

            ; print blank cell
            print_not_taken:
                push offset blank
                call PrintString
            
            ; print a new line
            check_print_new_line:            
                mov ax,cx
                add ax,2
                mov bl,3
                div bl
                cmp ah,0
                jne continue_loop
                push offset separator
                call PrintString
                push offset newLine
                call PrintString

            continue_loop:
                inc di
        loop print_values

        pop di
        pop bx
        pop ax
        pop cx
        pop dx
        pop bp
        ret 2
    DrawGrid ENDP

; char ReadCharacter(void)
; The result is stored in AL
ReadCharacter PROC NEAR
    push bp
    mov bp,sp

    mov ah,01h
    int 21h
    
    pop bp
    ret 
ReadCharacter ENDP

; void ReadString(char *buffer,char delimiter)
; The buffer will be in ASCIIZ format
ReadString PROC NEAR
    push bp
    mov bp,sp

    push ax
    push di
    push si
    push bx

    mov si,[bp + 4]
    mov bx,[bp + 6]

    read_characters:
        call ReadCharacter
        cmp al,byte ptr [bx] ; if all is equal to the delimiter than we can stop
        je done
        mov byte ptr [si],al 
        inc si
        jmp read_characters
    
    done:
    ; add the '$' terminator
    inc si
    mov byte ptr[si],'$'

    pop bx
    pop si
    pop di
    pop ax
    pop bp
    ret 4
ReadString ENDP

; int CharToInt(char c)
; the result will be stored in AL
; in case of an error ax will be -1
CharToInt PROC NEAR
    push bp
    mov bp,sp
    push bx

    mov bx,[bp+4]
    mov ax,bx

    ; get the decimal value from the ascii code
    sub al,30h

    ; check if it's valid digit
    cmp al,9
    jg error
    cmp al,0
    jl error
    jmp success

    error:
        mov ax,-1
    
    success:

    pop bx
    pop bp
    ret 2
CharToInt ENDP

; void ClearScreen(void)
ClearScreen PROC NEAR
    push bp
    mov bp,sp
    push cx

    mov cx,100
    add_new_lines:
        push offset newLine
        call PrintString
    loop add_new_lines

    pop cx
    pop bp
    ret
ClearScreen ENDP

; int ReadDigit(void)
; The result is stored in al.
ReadDigit PROC  NEAR
    push bp
    mov bp,sp

    ; read the character
    call ReadCharacter
    
    ; convert it to int
    push ax
    call CharToInt

    pop bp
    ret
ReadDigit ENDP

; int CheckWin(char *grid)
; the function returns 1 if player 1 won,2 if player 2 won,3 if it's a tie and 0 otherwise
CheckWin PROC NEAR
    push bp
    mov bp,sp

    push si
    push di
    push cx
    push bx

    ; make sure al is 0
    mov al,0

    ; si will contain the offset of the grid
    mov si,[bp+4]
    
    mov di,si

    ; number of iterations needed
    mov cx,3
    
    horizontal_check:
        mov bl,byte ptr [si+1]
        cmp byte ptr [si],bl
        jne next_h_check
        mov bl,byte ptr [si+2]
        cmp byte ptr [si],bl
        jne next_h_check

        cmp byte ptr [si],0
        je next_h_check
        mov al,byte ptr [si] ; we have a winner
        jmp end_check

        next_h_check:
            add si,3

    loop horizontal_check

    ; if the horizontal check did not yield any result
    ; continue with the vertical check

    mov cx,3; restore the counter
    mov si,di ; restore si

    vertical_check:
        mov bl,byte ptr [si+3]
        cmp byte ptr[si],bl
        jne next_v_check
        mov bl,byte ptr [si+6]
        cmp byte ptr[si],bl
        jne next_v_check

        cmp byte ptr[si],0
        je next_v_check
        mov al,byte ptr[si]
        jmp end_check

        next_v_check:
            add si,1
    loop vertical_check


    mov si,di

    main_diagonal_check:
        mov bl,byte ptr [si + 4]
        cmp byte ptr [si],bl
        jne secondary_diagonal_check
        mov bl,byte ptr [si + 8]
        cmp byte ptr [si],bl
        jne secondary_diagonal_check
        cmp byte ptr [si],0
        je secondary_diagonal_check
        mov al,byte ptr[si]
        jmp end_check
        
    secondary_diagonal_check:
        mov bl,byte ptr [si + 4]
        cmp byte ptr[si+2],bl
        jne end_check
        mov bl,byte ptr[si+6]
        cmp byte ptr [si+2],bl
        jne end_check
        cmp byte ptr [si+2],0
        je end_check
        mov al,byte ptr[si+2]
        
    end_check:
    pop bx
    pop cx
    pop di
    pop si
    pop bp
    ret 2
CheckWin ENDP

; void GameOverCheck(char *grid,int gridLength)
; The value is stored in AL(AL=1 if the game is over and AL=0 otherwise)
GameOverCheck PROC NEAR
    push bp
    mov bp,sp
    push si
    push cx

    mov si,[bp+4]
    mov cx,[bp+6]
    mov al,0

    ; check if there is a cell that isn't taken
    check:
        cmp byte ptr[si],0
        je not_over
        inc si
    loop check

    ; no empty cell was found,game over
    mov al,1

    not_over:
    pop cx
    pop si
    pop bp
    ret 4
GameOverCheck ENDP

; void StartGame(void)
StartGame PROC NEAR
    push bp
    mov bp,sp
    push bx
    push cx

    main_loop:
        ; clear screen on each update
        call ClearScreen

        ; print a welcome message
        push offset welcomeMsg
        call PrintString

        ; print current player number
        push offset currentPlayerMsg
        call PrintString

        cmp currentPlayer,1
        jne print_player2_msg
        push offset player1Msg
        call PrintString
        jmp msg_done

        print_player2_msg:
        push offset player2Msg
        call PrintString

        msg_done:
        ; draw the grid
        push offset grid
        call DrawGrid

        ; check if any of the players have won
        push offset grid
        call CheckWin
        cmp al,0
        je next_check

        ; check if player 1 won and print the corresponding message
        cmp al,1
        jne player2_won
        push offset player1WinMsg
        call PrintString
        jmp finish
        
        ; check if player 2 won and print the corresponding message
        player2_won:
        push offset player2WinMsg
        call PrintString
        jmp finish

        next_check:
        ; check if there are any moves left
        push word ptr gridLength
        push offset grid
        call GameOverCheck
        cmp al,1
        jne continue_game
        push offset gameOverMsg
        call PrintString
        jmp finish

        continue_game:

        ; read column value
        push offset columnMsg
        call PrintString
        call ReadDigit

        cmp al,2
        jg continue_game_loop

        mov bl,al ; store the result in bl for now
        
        ; print a new line
        push offset newLine
        call PrintString

        ; read row value
        push offset rowMsg
        call PrintString
        call ReadDigit

        cmp al,2
        jg continue_game_loop

        mov cl,al ; store the result in cl 

        ; compute 3*column
        mov al,3
        mul bl

        mov ch,0
        add ax,cx

        mov si,offset grid
        add si,ax

        cmp byte ptr[si],0
        jne continue_game_loop
        mov al,currentPlayer
        mov byte ptr[si],al

        ; change the currentPlayer number
        cmp currentPlayer,1
        je change_to_player2
        mov currentPlayer,1
        jmp main_loop

        change_to_player2:
            mov currentPlayer,2
        
        ; continue the loop
        continue_game_loop:

        jmp main_loop

    finish:
    pop cx
    pop bx
    pop bp
    ret 
StartGame ENDP

start:

    mov ax,data
    mov ds,ax

    call StartGame

    mov ax,4c00h
    int 21h
code ends
end start