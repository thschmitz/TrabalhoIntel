
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
NomeTesteAleatorio db 	"Teste", 0
FileNameSrc		db		"IN.txt", 0		; Nome do arquivo a ser lido
FileNameDst		db		"OUT.txt", 0	; Nome do arquivo a ser escrito
FileHandleSrc	dw		0				; Handler do arquivo origem
FileHandleDst	dw		0				; Handler do arquivo destino
FileBuffer		db		2000 dup (?)	; Buffer de leitura/escrita do arquivo
NewBuffer		db		2000 dup (?)	; Buffer de leitura/escrita do arquivo
OutputBuffer    db 		2000 dup(?) 	; Espaço para os BarCodes (64 bytes)


BarCodeTable DB 101011b     ; 0
	DB 1101011b    ; 1
	DB 1001011b    ; 2
	DB 1100101b    ; 3
	DB 1011011b    ; 4
	DB 1101101b    ; 5
	DB 1001101b    ; 6
	DB 1010011b    ; 7
	DB 1101001b    ; 8
	DB 1101101b    ; 9
	DB 101101b     ; -
	DB 1011001b    ; SS



MsgErroOpenFile		db	"Erro: Nao foi possivel fazer a abertura do arquivo.", CR, LF, 0
MsgErroCreateFile	db	"Erro: Nao foi possivel fazer a criacao do arquivo.", CR, LF, 0
MsgErroReadFile		db	"Erro: Nao foi possível fazer a leitura do arquivo.", CR, LF, 0
MsgErroSemStart		db	"Erro: Nao foi encontrado a palavra 'START' no arquivo.", CR, LF, 0
MsgErroSemStop		db	"Erro: Nao foi encontrado a palavra 'STOP' no arquivo.", CR, LF, 0
MsgErroWriteFile	db	"Erro: Nao foi possivel fazer a escrita do arquivo.", CR, LF, 0
MsgErrorCaracterInvalido db "Erro: Nao foi possivel fazer a traducao de um caracter que eh invalido.", CR, LF, 0

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
	
TerminouArquivo:

	call    criaNovoBuffer

	call    transformaEmBarcode


	lea 	bx, OutputBuffer
	call 	printf_s



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
;Função que cria um novo buffer com o conteudo do arquivo que interessa
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

criaNovoBuffer_loop2:
	inc bx
	mov 	dl, [bx]
	cmp     byte ptr dl, 0Ah ; CR (Carriage Return)
	je criaNovoBuffer_loop2
	cmp     byte ptr dl, 0Dh ; LF (Line Feed)
	je criaNovoBuffer_loop2

	dec bx
criaNovoBuffer_insere:
	add     ax, si
	inc 	bx
	mov 	dl, [bx]
	cmp     byte ptr dl, 0 
	je		criaNovoBuffer_sem_stop

	mov 	byte ptr [si], dl
	inc 	si

	cmp 	byte ptr dl, 'S' ; Verifica se o próximo caractere é 'S' de 'STOP'
	jne		criaNovoBuffer_insere
	dec si 

	mov 	dl, [bx + 1]
	cmp 	byte ptr dl, 'T' ; Verifica se o próximo caractere é 'T' de 'STOP'
	jne		criaNovoBuffer_insere
	mov 	dl, [bx + 2]
	cmp 	byte ptr dl, 'O' ; Verifica se o próximo caractere é 'O' de 'STOP'
	jne		criaNovoBuffer_insere
	mov 	dl, [bx + 3]
	cmp 	byte ptr dl, 'P' ; Verifica se o próximo caractere é 'P' de 'STOP'
	jne		criaNovoBuffer_insere
	add 	bx, 4

	mov     [si], 0
	
	jmp     criaNovoBuffer_print
	
criaNovoBuffer_end:
	inc bx
	jmp criaNovoBuffer_loop

criaNovoBuffer_sem_start:
	cmp cx, 0
	lea bx, MsgErroSemStart
	call printf_s
	.exit

criaNovoBuffer_print:
	lea bx, NewBuffer

	call printf_s
	ret

criaNovoBuffer_sem_stop:
	lea bx, MsgErroSemStop
	call printf_s
	.exit

criaNovoBuffer    endp

;--------------------------------------------------------------------
;Função que traduz cada caracter do novo buffer em um barcode 
;		
;Sai:   
;		Buffer com dados em barcode
;--------------------------------------------------------------------
transformaEmBarcode proc near
	mov     cx, 0
	lea 	si, OutputBuffer
	lea 	bx, NewBuffer
	
	;mov     dl, 1011001b
	;mov     [si + cx], dl
	;inc     cx

transformaEmBarcode_loop:
	mov     dl, [bx]

	inc bx

	cmp     byte ptr dl, 0    ; Verifica se o buffer está vazio
	je      transformaEmBarcode_fim_traducao    ; Se estiver, retorna

	cmp 	byte ptr dl, 13
	je 		transformaEmBarcode_loop

	cmp 	byte ptr dl, 10
	je 		transformaEmBarcode_loop

	mov 	cx, 0
	cmp     byte ptr dl, '0'    ; Verifica se o caractere é '0'
	je      transformaEmBarcode_codigo    ; Se for, pula para a função que transforma em barcode

	mov 	cx, 1
	cmp     byte ptr dl, '1'    ; Verifica se o caractere é '1'
	je      transformaEmBarcode_codigo    ; Se for, pula para a função que transforma em barcode

	mov 	cx, 2
	cmp     byte ptr dl, '2'    ; Verifica se o caractere é '2'
	je      transformaEmBarcode_codigo    ; Se for, pula para a função que transforma em barcode

	mov 	cx, 3
	cmp     byte ptr dl, '3'    ; Verifica se o caractere é '3'
	je      transformaEmBarcode_codigo    ; Se for, pula para a função que transforma em barcode

	mov 	cx, 4
	cmp     byte ptr dl, '4'    ; Verifica se o caractere é '4'
	je      transformaEmBarcode_codigo    ; Se for, pula para a função que transforma em barcode

	mov 	cx, 5
	cmp     byte ptr dl, '5'    ; Verifica se o caractere é '5'
	je      transformaEmBarcode_codigo    ; Se for, pula para a função que transforma em barcode

	mov 	cx, 6
	cmp     byte ptr dl, '6'    ; Verifica se o caractere é '6'
	je      transformaEmBarcode_codigo    ; Se for, pula para a função que transforma em barcode

	mov 	cx, 7
	cmp     byte ptr dl, '7'    ; Verifica se o caractere é '7'
	je      transformaEmBarcode_codigo    ; Se for, pula para a função que transforma em barcode

	mov 	cx, 8
	cmp     byte ptr dl, '8'    ; Verifica se o caractere é '8'
	je      transformaEmBarcode_codigo    ; Se for, pula para a função que transforma em barcode

	mov 	cx, 9
	cmp     byte ptr dl, '9'    ; Verifica se o caractere é '9'
	je      transformaEmBarcode_codigo    ; Se for, pula para a função que transforma em barcode

	mov 	cx, 10
	cmp     byte ptr dl, '-'    ; Verifica se o caractere é '-'
	je      transformaEmBarcode_codigo    ; Se for, pula para a função que transforma em barcode

	jmp     transformaEmBarcode_erro_caractere_invalido

transformaEmBarcode_erro_caractere_invalido:
	lea     bx, MsgErrorCaracterInvalido
	call    printf_s
	.exit

transformaEmBarcode_codigo:
	push 	bx
	lea 	bx, BarCodeTable
	add 	bx, cx
	mov 	dl, [bx]
	
loop_acha_primeiro_0:
	shl	 dl, 1
	jc loop_coloca_valores_0
	jmp loop_acha_primeiro_0

loop_coloca_valores_0:
	mov  ax, 30h
	adc  ax, 0

	mov	 [si], ax
	inc cx
	inc si

	cmp 	dl, 0
	je  	loop_coloca_valores_0_acaba

	shl 	dl, 1
	jmp 	loop_coloca_valores_0

loop_coloca_valores_0_acaba:
	pop 	bx
    jmp     transformaEmBarcode_loop

transformaEmBarcode_fim_traducao:
    mov     dl, 1011001b           ; Código de finalização
    mov     [OutputBuffer + cx], dl
    inc     cx
    ret


transformaEmBarcode endp

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


	



