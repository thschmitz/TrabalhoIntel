
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
MsgErroSemStop		db	"Erro: Nao foi encontrado a palavra 'STOP' no arquivo.", CR, LF, 0
MsgErroWriteFile	db	"Erro: Nao foi possivel fazer a escrita do arquivo.", CR, LF, 0
MsgCRLF				db	CR, LF, 0

	.code
	.startup

	lea		dx,FileNameSrc
	call	fopen
	mov		FileHandleSrc,bx
	jnc		Continua2
	lea		bx, MsgErroOpenFile
	call	printf_s
	.exit	1
Continua1:

	lea		dx,FileNameDst
	call	fcreate
	mov		FileHandleDst,bx
	jnc		Continua2
	mov		bx,FileHandleSrc
	call	fclose
	lea		bx, MsgErroCreateFile
	call	printf_s
	.exit	1
Continua2:

	mov		bx,FileHandleSrc    
	call	getChar
	jnc		Continua3
	lea		bx, MsgErroReadFile
	call	printf_s
	mov		bx,FileHandleSrc
	call	fclose
	mov		bx,FileHandleDst
	call	fclose
	.exit	1
Continua3:

	cmp		ax,0
	jz		TerminouArquivo
	jmp 	Continua2
Continua4:

	mov		bx,FileHandleDst
	call	setChar
	jnc		Continua2

	mov		bx,FileHandleSrc		; Fecha arquivo origem
	call	fclose
	mov		bx,FileHandleDst		; Fecha arquivo destino
	call	fclose
	.exit	1
	
TerminouArquivo:

	call    criaNovoBuffer
	mov		bx,FileHandleSrc	; Fecha arquivo origem
	call	fclose
	mov		bx,FileHandleDst	; Fecha arquivo destino
	call	fclose
	.exit	0


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
	je 		criaNovoBuffer_sem_start	; Se estiver, retorna

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
	add     bx, 4
	lea 	si, NewBuffer

criaNovoBuffer_insere:
	add     ax, si
	inc 	bx
	mov 	dl, [bx]
	cmp     byte ptr dl, 0 ; 
	je		criaNovoBuffer_sem_stop
	cmp 	byte ptr dl, 'S' ; Verifica se o próximo caractere é 'S' de 'STOP'
	je		criaNovoBuffer_print

	mov 	byte ptr [si], dl
	inc 	si
	
	jmp     criaNovoBuffer_insere
	
criaNovoBuffer_end:
	inc bx
	jmp criaNovoBuffer_loop

criaNovoBuffer_sem_start:
	cmp cx, 0
	lea bx, MsgErroSemStart
	call printf_s
	.exit

criaNovoBuffer_print:
	dec NewBuffer
	lea bx, NewBuffer

	call printf_s
	ret

criaNovoBuffer_sem_stop:
	lea bx, MsgErroSemStop
	call printf_s
	.exit

criaNovoBuffer    endp

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


	



