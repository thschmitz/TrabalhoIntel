
;
;====================================================================
;	- Escrever um programa para ler um arquivo texto e 
;		apresentá-lo na tela
;	- O usuário devem informar o nome do arquivo, 
;		assim que for apresentada a mensagem: Nome do arquivo: 
;====================================================================
;
	.model		small
	.stack
		
CR		equ		0dh
LF		equ		0ah

	.data

ContadorBuffer  dw 	0
PalavraStart    db		"START", 0		; Palavra que indica o inicio da leitura
PalavraStop     db		"STOP", 0		; Palavra que indica o fim da leitura
FileNameSrc		db		"IN.txt", 0		; Nome do arquivo a ser lido
FileNameDst		db		"OUT.txt", 0	; Nome do arquivo a ser escrito
FileHandleSrc	dw		0				; Handler do arquivo origem
FileHandleDst	dw		0				; Handler do arquivo destino
FileBuffer		db		2000 dup (?)	; Buffer de leitura/escrita do arquivo
NewBuffer		db		2000 dup (?)	; Buffer de leitura/escrita do arquivo

MsgPedeArquivoSrc	db	"Nome do arquivo origem: ", 0
MsgPedeArquivoDst	db	"Nome do arquivo destino: ", 0
MsgErroOpenFile		db	"Erro: Nao foi possivel fazer a abertura do arquivo.", CR, LF, 0
MsgErroCreateFile	db	"Erro: Nao foi possivel fazer a criacao do arquivo.", CR, LF, 0
MsgErroReadFile		db	"Erro: Nao foi possível fazer a leitura do arquivo.", CR, LF, 0
MsgErroSemStart		db	"Erro: Nao foi encontrado a palavra 'START' no arquivo.", CR, LF, 0
MsgErroWriteFile	db	"Erro: Nao foi possivel fazer a escrita do arquivo.", CR, LF, 0
; Abrir o arquivo de origem
lea		dx,FileNameSrc		; Carrega o endereço do nome do arquivo de origem em DX
call	fopen				; Chama a função fopen para abrir o arquivo
mov		FileHandleSrc,bx	; Move o handle do arquivo para BX
jnc		Continua2			; Se não houver erro, pula para Continua2
lea		bx, MsgErroOpenFile	; Carrega a mensagem de erro de abertura do arquivo em BX
call	printf_s			; Chama a função printf_s para imprimir a mensagem de erro
.exit	1						; Sai do programa com código de erro 1

Continua1:
; Criar o arquivo de destino
lea		dx,FileNameDst		; Carrega o endereço do nome do arquivo de destino em DX
call	fcreate				; Chama a função fcreate para criar o arquivo
mov		FileHandleDst,bx	; Move o handle do arquivo para BX
jnc		Continua2			; Se não houver erro, pula para Continua2
mov		bx,FileHandleSrc	; Move o handle do arquivo de origem para BX
call	fclose				; Chama a função fclose para fechar o arquivo de origem
lea		bx, MsgErroCreateFile	; Carrega a mensagem de erro de criação do arquivo em BX
call	printf_s			; Chama a função printf_s para imprimir a mensagem de erro
.exit	1						; Sai do programa com código de erro 1

Continua2:
; Ler caracteres do arquivo de origem
mov		bx,FileHandleSrc	; Move o handle do arquivo de origem para BX
call	getChar				; Chama a função getChar para ler um caractere do arquivo
jnc		Continua3			; Se não houver erro, pula para Continua3
lea		bx, MsgErroReadFile	; Carrega a mensagem de erro de leitura do arquivo em BX
call	printf_s			; Chama a função printf_s para imprimir a mensagem de erro
mov		bx,FileHandleSrc	; Move o handle do arquivo de origem para BX
call	fclose				; Chama a função fclose para fechar o arquivo de origem
mov		bx,FileHandleDst	; Move o handle do arquivo de destino para BX
call	fclose				; Chama a função fclose para fechar o arquivo de destino
.exit	1						; Sai do programa com código de erro 1

Continua3:
; Verificar se chegou ao final do arquivo
cmp		ax,0				; Compara o valor de AX com 0
jz		TerminouArquivo		; Se for igual a 0, pula para TerminouArquivo
jmp 	Continua2			; Caso contrário, volta para Continua2

Continua4:
; Escrever o caractere no arquivo de destino
mov		bx,FileHandleDst	; Move o handle do arquivo de destino para BX
call	setChar				; Chama a função setChar para escrever o caractere no arquivo
jnc		Continua2			; Se não houver erro, pula para Continua2

mov		bx,FileHandleSrc	; Move o handle do arquivo de origem para BX
call	fclose				; Chama a função fclose para fechar o arquivo de origem
mov		bx,FileHandleDst	; Move o handle do arquivo de destino para BX
call	fclose				; Chama a função fclose para fechar o arquivo de destino
.exit	1						; Sai do programa com código de erro 1
	
TerminouArquivo:
; Procurar pela palavra "START" no arquivo
call    procuraStart		; Chama a função procuraStart para procurar pela palavra "START" no arquivo
mov		bx,FileHandleSrc	; Move o handle do arquivo de origem para BX
call	fclose				; Chama a função fclose para fechar o arquivo de origem
mov		bx,FileHandleDst	; Move o handle do arquivo de destino para BX
call	fclose				; Chama a função fclose para fechar o arquivo de destino
.exit	0					; Sai do programa com código de sucesso 0


;--------------------------------------------------------------------
;Função	Abre o arquivo cujo nome está no string apontado por DX
;		boolean fopen(char *FileName -> DX)
;Entra: DX -> ponteiro para o string com o nome do arquivo
;Sai:   BX -> handle do arquivo
;       CF -> 0, se OK
;--------------------------------------------------------------------
fopen	proc	near
	mov		al,0
	mov		ah,3dh
	int		21h
	mov		bx,ax
	ret
fopen	endp

;--------------------------------------------------------------------
;Função Cria o arquivo cujo nome está no string apontado por DX
;		boolean fcreate(char *FileName -> DX)
;Sai:   BX -> handle do arquivo
;       CF -> 0, se OK
;--------------------------------------------------------------------
fcreate	proc	near
	mov		cx,0
	mov		ah,3ch
	int		21h
	mov		bx,ax
	ret
fcreate	endp

;--------------------------------------------------------------------
;Entra:	BX -> file handle
;Sai:	CF -> "0" se OK
;--------------------------------------------------------------------
fclose	proc	near
	mov		ah,3eh
	int		21h
	ret
fclose	endp

;--------------------------------------------------------------------
;Função	Le um caractere do arquivo identificado pelo HANLDE BX
;		getChar(handle->BX)
;Entra: BX -> file handle
;Sai:   
;		AX -> numero de caracteres lidos
;		CF -> "0" se leitura ok
;--------------------------------------------------------------------
getChar proc near
    mov     cx, 1                  ; Number of bytes to read
    lea     si, FileBuffer         ; Load the base address of FileBuffer into SI
    mov     dx, si                 ; Copy base address to DX (used by DOS)
    mov     ax, ContadorBuffer     ; Load FileCounter into AX
    add     dx, ax                 ; Adjust DX to point to the current position
    mov     ah, 3Fh                ; DOS function: Read from file
    int     21h                    ; Call DOS interrupt
    inc     ContadorBuffer         ; Increment the counter for the next read
    ret                            ; Return to the caller
getChar endp

;--------------------------------------------------------------------
;Função que procura a palavra "START" no arquivo
;		
;Sai:   
;		NovoBuffer -> buffer com o conteudo do arquivo
;--------------------------------------------------------------------
criaNovoBuffer    proc near
	lea bx, FileBuffer

criaNovoBuffer_loop:
	mov 	dl, [bx]	; Carrega o primeiro caractere do buffer
	
	cmp 	dl, 0		; Verifica se o buffer está vazio
	je 		criaNovoBuffer_ret	; Se estiver, retorna

	cmp     byte ptr dl, 'S'             ; Verifica se o caractere é 'S'
	jne     criaNovoBuffer_end    ; Se não for, sai do loop

	mov dl, [bx + 1]

	cmp     byte ptr dl, 'T'  ; Verifica se o próximo caractere é 'T'
	jne     criaNovoBuffer_end    ; Se não for, sai do loop

	mov dl, [bx + 2]

	cmp     byte ptr dl, 'A'; Verifica se o próximo caractere é 'A'
	jne     criaNovoBuffer_end    ; Se não for, sai do loop

	mov dl, [bx + 3]

	cmp     byte ptr dl, 'R'; Verifica se o próximo caractere é 'R'
	jne     criaNovoBuffer_end    ; Se não for, sai do loop

	mov dl, [bx + 4]

	cmp     byte ptr dl, 'T'; Verifica se o próximo caractere é 'T'
	jne     criaNovoBuffer_end    ; Se não for, sai do loop

	mov dl, [bx + 5]	; Adicione essa linha para verificar o próximo caractere

	cmp     byte ptr dl, 0 ; Verifica se o próximo caractere é nulo
	jne     criaNovoBuffer_print   ; Imprime a mensagem

criaNovoBuffer_end:
	inc bx
	jmp criaNovoBuffer_loop

criaNovoBuffer_ret:
	cmp cx, 0
	lea bx, MsgErroSemStart
	call printf_s
	.exit

criaNovoBuffer_print:
	lea bx, PalavraStart
	call printf_s
	ret

procuraStart    endp

;--------------------------------------------------------------------
;Entra: BX -> file handle
;       dl -> caractere
;Sai:   AX -> numero de caracteres escritos
;		CF -> "0" se escrita ok
;--------------------------------------------------------------------
setChar	proc	near
	mov		ah,40h
	mov		cx,1
	mov		FileBuffer,dl
	lea		dx,FileBuffer
	int		21h
	ret
setChar	endp	
	
;--------------------------------------------------------------------
;Função Escrever um string na tela
;		printf_s(char *s -> BX)
;--------------------------------------------------------------------
printf_s	proc	near
	mov		dl,[bx]
	cmp		dl,0
	je		ps_1

	push	bx
	mov		ah,2
	int		21H
	pop		bx

	inc		bx		
	jmp		printf_s
		
ps_1:
	ret
printf_s	endp

;--------------------------------------------------------------------
		end
;--------------------------------------------------------------------


	



