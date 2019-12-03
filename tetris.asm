.model small
.stack 100H
.data
    ;Textos que serao impressos na Tela
    ;-----------------------------------  
        ; MENU
        TETRIS  db 15, ' T E T R I S ', 15,'$'
        JOGAR db '(J)ogar$'
        SAIR  db '(S)air$'
        DESENV db 'Desenvolvido por Marcelo e Franco, 2019$'
    
    
        ; Layout Jogo
        QUADRADO_CHAR equ 00DBh ; ASCII Character
        LATERAL_JOGO  db QUADRADO_CHAR, '          ', QUADRADO_CHAR,'$'
        BASE_JOGO db 12 dup(QUADRADO_CHAR), '$'
        BASE_CAIXA_PECA db 8 dup(QUADRADO_CHAR), '$'
        LATERAL_CAIXA_PECA db QUADRADO_CHAR, '      ', QUADRADO_CHAR,'$'
        SCORE_MSG db 'SCORE$'
        
        ; Pecas (Nomes retirados de https://en.wikipedia.org/wiki/Tetromino)
        PECA_S db '    $','    $',' ',QUADRADO_CHAR,QUADRADO_CHAR,' $',QUADRADO_CHAR,QUADRADO_CHAR,'  $'
        PECA_T db '    $','    $','  ',QUADRADO_CHAR,' $',' ',QUADRADO_CHAR,QUADRADO_CHAR,QUADRADO_CHAR,'$'
        PECA_J db '    $','    $',QUADRADO_CHAR,'   $',QUADRADO_CHAR,QUADRADO_CHAR,QUADRADO_CHAR,' ','$'
        PECA_O db '    $','    $',' ',QUADRADO_CHAR,QUADRADO_CHAR,' $',' ',QUADRADO_CHAR,QUADRADO_CHAR,' $'
        PECA_I db '    $','    $','    $',QUADRADO_CHAR,QUADRADO_CHAR,QUADRADO_CHAR,QUADRADO_CHAR,'$'
        PECA_L db '    $','    $','   ',QUADRADO_CHAR,'$',' ',QUADRADO_CHAR,QUADRADO_CHAR,QUADRADO_CHAR,'$'
        PECA_Z db '    $','    $',QUADRADO_CHAR,QUADRADO_CHAR,'  $',' ',QUADRADO_CHAR,QUADRADO_CHAR,' $'
            
    
    ;  ~Variaveis ~ Jogo
    ;------------------------------------
    SCORE_JOGO db 5 dup('0'),'$'  ; Texto do Score
    SCORE_JOGO_HEX dw ?       ; Pontuacao (hex)
   
.code


PushAXBX macro 
    push AX 
    push BX 
endm

PushAXBXCX macro 
    PushAXBX 
    push CX 
endm

PushAXBXCXDX macro 
    PushAXBXCX
    push DX 
endm
    
PopAXBX macro 
    pop  BX
    pop  AX 
endm

PopAXBXCX macro 
    pop  CX 
    PopAXBX 
endm

PopAXBXCXDX macro 
    pop  DX 
    PopAXBXCX 
endm

GENERATE_RANDOM proc ; Return AL
    push BX
    push CX
    push DX
    
    MOV AH, 00h  ; interrupts to get system time        
    INT 1AH      ; CX:DX now hold number of clock ticks since midnight      
    mov  ax, dx
    xor  dx, dx
    mov  cx, 6    
    div  cx       ; here dx contains the remainder of the division - from 0 to 6
    add  dl, '0'  ; to ascii from '0' to '6'
    xor  ax, ax
    mov  al, dl
    sub  al, '0'
    
    pop DX
    pop CX
    pop BX
    ret
endp

CHAR_DISPLAY proc  ; Proc que imprime na tela UM caractere em determinada cor (BL)
    PushAXBXCX
    xor  AH, AH
    xor  CX, CX
    mov  AH, 09h            ;Servico da interrupcao 10h para imprimir caractere na tela  
    mov  CX, 01h            ;Numero de vezes que o caractere sera mostrado na tela
    int  10h                ;Interrupcao de video 10h   
    PopAXBXCX
    ret
endp

GOTO_XY proc   ;Macro que seta o cursor em uma posicao X [BL],Y [BH]  AH=02h    BH = Page Number, DH = Row, DL = Column 
    PushAXBXCXDX  
    xor AX, AX
    mov AH, 2       ;Servico da interrupcao 10h para alterar posicao do cursor 
    int 10h         ;Interrupcao de video 10h
    popAXBXCXDX
    ret
endp

IMP_PECA_GENERICO proc ; SI  = offset peca ; DH = linha da peca; DL = coluna da peca; BL = cor da peca
  PushAXBXCXDX
   mov CX,4
   imprime_peca:
    call IMP_STRING
    inc DH
    inc SI
    loop imprime_peca
  PopAXBXCXDX 
  ret
endp

IMP_PECA_T proc
    push BX
    mov SI, OFFSET PECA_T
    mov BL, 04h
    call IMP_PECA_GENERICO
    pop BX
ret
endp

IMP_PECA_S proc
    push BX
    mov SI, OFFSET PECA_S
    mov BL, 06h
    call IMP_PECA_GENERICO
    pop BX
ret
endp

IMP_PECA_Z proc
    push BX
    mov SI, OFFSET PECA_Z
    mov BL, 0Eh
    call IMP_PECA_GENERICO
    pop BX
ret
endp

IMP_PECA_I proc
    push BX
    mov SI, OFFSET PECA_I
    mov BL, 02h
    call IMP_PECA_GENERICO
    pop BX
ret
endp

IMP_PECA_O proc
    push BX
    mov SI, OFFSET PECA_O
    mov BL, 03h
    call IMP_PECA_GENERICO
    pop BX
ret
endp

IMP_PECA_L proc
    push BX
    mov SI, OFFSET PECA_L
    mov BL, 01h
    call IMP_PECA_GENERICO
    pop BX
ret
endp

IMP_PECA_J proc
    push BX
    mov SI, OFFSET PECA_J
    mov BL, 09h
    call IMP_PECA_GENERICO
    pop BX
ret
endp

IMP_PECA proc ; al = peca
    cmp  AL, 00d
    je   IMP_PECA_T
    cmp  AL, 01d
    je   IMP_PECA_S
    cmp  AL, 02d
    je   IMP_PECA_Z
    cmp  AL, 03d
    je   IMP_PECA_I
    cmp  AL, 04d
    je   IMP_PECA_O
    cmp  AL, 05h
    je   IMP_PECA_L
    jmp  IMP_PECA_J
ret
endp

IMP_STRING proc ; Proc recebe a palavra, posicao e cor para imprimir na tela [SI palavra, DH posx, DL posy, BL cor]
    PushAXBXCXDX
    ;mov SI, AX
    ;xor AX, AX
    mov  AL, [SI]       ;Aponta para o endereco na memoria da string.
    loop_imp_string:
        call GOTO_XY            ;Chama o macro que seta o cursor [x,y]
        call CHAR_DISPLAY    ;Chama o macro que imprime na tela o caractere colorido
        inc SI             ;Incremente a posicao na memoria para o proximo caractere
        inc DL              ;Incrementa a posicao x na tela para impressao do proximo caractere 
        mov AL, [SI]       ;Aponta para o endereco na memoria da string.
        cmp AL, '$'       ;Checa se chegou ao fim da string
        jne loop_imp_string
    PopAXBXCXDX
    ret
endp

LIMPAR_TELA proc  ; Essa proc limpa a tela do usuario
    PushAXBXCXDX   
    mov AX, 0620h
    mov BX, 0h
    mov CX, 0h
    mov DX, 1998h
    int 10h
    PopAXBXCXDX
    ret
endp

GERAR_PROXIMA_PECA proc
    PushAXBXCXDX
    call GENERATE_RANDOM
    mov  DH, 02h
    mov  DL, 1Dh
    call IMP_PECA
    PopAXBXCXDX
ret
endp

TELA_JOGO proc
    PushAXBXCXDX   
    call LIMPAR_TELA
    
    ; Exibe Score (Pontuacao)
    mov SI, offset SCORE_JOGO
    mov DH, 02h
    mov DL, 04h
    mov BL, 06h  
    call IMP_STRING    
    
    ; Exibe Score (String)
    mov SI, offset SCORE_MSG
    mov DH, 01h
    mov DL, 04h
    mov BL, 07h  
    call IMP_STRING  
    
    ; Linha Superior e inferior do Jogo
    mov  SI, offset BASE_JOGO
    mov  DX, 010Ch
    call IMP_STRING
    mov DL, 0Ch
    mov DH, 18h
    mov  SI, offset BASE_JOGO
    call IMP_STRING
    
    ; Linhas Laterais Jogo
    mov CX,16h
    LOOP_TELA_JOGO:
    mov  SI, offset LATERAL_JOGO  
        inc   CL
        mov DL, 0Ch
        mov  DH, CL
        dec  CL
        mov  DL, 0Ch
        call IMP_STRING
        loop LOOP_TELA_JOGO
    
    ; Linha Superior e inferior Caixa Proxima Peca    
    mov  SI, offset BASE_CAIXA_PECA
    mov  DH, 1h
    mov  DL, 1Bh
    call IMP_STRING
    mov  SI, offset BASE_CAIXA_PECA
    mov DH, 08h
    call IMP_STRING
   
    mov CX,06h
    LOOP_TELA_CAIXA:
    mov  SI, offset LATERAL_CAIXA_PECA  
        inc  CL
        mov  DH, CL
        dec  CL
        call IMP_STRING
        loop LOOP_TELA_CAIXA

    ; Imprime Primeira Peca
    call GERAR_PROXIMA_PECA

    PopAXBXCXDX
    ret
endp

  
TELA_INICIAL proc
   PushAXBXCXDX
   call LIMPAR_TELA
   
   ; Exibe tela inicial para o usuario
   mov SI, offset TETRIS ; Titulo
   mov BL, 02h
   mov DH, 05h 
   mov DL, 0Bh ;12d
   call IMP_STRING
  
   ; Exibe Tetraminos
   mov DH, 06h
   mov DL, 06h
   mov AL, 00h
   call IMP_PECA ; Imprime J
   
   mov DL, 0Bh
   inc AL
   call IMP_PECA   
   
   mov DL, 0Fh
   inc AL
   call IMP_PECA
   
   mov DL, 13h
   inc AL
   call IMP_PECA
   
   mov DL, 17h
   inc AL
   call IMP_PECA
   
   mov DL, 1Eh
   inc AL
   call IMP_PECA
   
   mov DL, 1Bh
   inc AL
   call IMP_PECA
   
   mov SI, offset JOGAR ; Opcao de Jogar
   mov BL, 0Fh
   mov DH, 0Fh 
   mov DL, 0Fh ; 15d
   call IMP_STRING
  
   mov SI, offset SAIR ; Opcao de Sair
   mov DH, 11h ;17d
   mov DL, 0Fh ; 15d
   call IMP_STRING

   mov SI, offset DESENV ; Mensagem Desenvolvedores
   mov BL, 04h
   mov DH, 016h ;22d
   mov DL, 01h 
   call IMP_STRING
   
   ; Realiza a leitura do usuario para entrar ou sair do jogo
   LEITURA_MENU:
       mov AX, 0h
       int 16h 
        
       cmp    AL, 'J'
       je     COMECA_JOGO
       cmp    AL, 'j'
       je     COMECA_JOGO
       cmp    AL, 'S'  
       je     FINALIZOU
       cmp    AL, 's'
       je     FINALIZOU  
   loopne LEITURA_MENU

   COMECA_JOGO:
   call TELA_JOGO
       
   FINALIZOU:
 
   PopAXBXCXDX
   ret
endp


MAIN:                               ;Bloco inicial do programa
    mov AX, @DATA
    mov DS, AX
        
    mov AH, 00h                     ;Servico de interrupcao que permite escrita na memoria de video 
    mov AL, 01h
    int 10h
    
    mov AX, 0b800h                  ;Inicio da regiao da memoria de video
    mov ES, AX
  
    call TELA_INICIAL
    
    
    ;mov AH, 4ch                     ;Procedimentos de finalizacao do programa
    ;mov AL, 00
    ;int 21h

end MAIN




