
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


Divisor10 		dw 		10
ChecksumBuffer 	db 		2000 dup(?) 	; Espaço para os Checksums (64 bytes)
Pesochecksum 	db		0
ChecksumTotal   dw 		0
Checksum 		dw		0
ColocaSeparador	db		1
MsgNewLine          db CR, LF, 0 ; Caractere para nova linha

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
MsgLinhaEmBranco	db 	"Erro: Nao foi possivel fazer a transcricao de uma linha em branco."

	.code
	.startup

	lea		dx,FileNameSrc
	call	fopen
	mov		FileHandleSrc,bx
	jnc		Continua1
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
	
TerminouArquivo:
	call    criaNovoBuffer

	lea 	si, OutputBuffer
	lea 	bx, NewBuffer
loop_transformacoes:
	call    transformaEmBarcode
	mov 	[si], 10
	inc 	si
	cmp 	byte ptr [bx], 0
	jne 	loop_transformacoes












	lea 	si, OutputBuffer
	mov 	bx, FileHandleDst
	mov 	cx, 0
loop_escrever_output:
	mov 	dl, [si]
	cmp 	byte ptr dl, 0
	je 		loop_escrever_output_fim
	push 	bx
	call 	setChar
	pop 	bx
	inc 	si
	jmp 	loop_escrever_output
	
loop_escrever_output_fim:
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
	;cmp     byte ptr dl, 0Ah ; CR (Carriage Return)
	;je criaNovoBuffer_loop2
	;cmp     byte ptr dl, 0Dh ; LF (Line Feed)
	;je criaNovoBuffer_loop2

	;dec bx
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

	
	mov      cx, 11
	call     transforma_em_barcode_exec

	mov 	dx, ds
	mov 	es, dx
	mov 	di, 0
	lea 	di, ChecksumBuffer
    xor     ax, ax                ; Zera AX para evitar resíduos

transformaEmBarcode_loop:
	mov     dl, [bx]
	mov 	[di], dl
	inc bx
	inc di

	cmp     byte ptr dl, 0    ; Verifica se o buffer está vazio
	je      transformaEmBarcode_fim_traducao    ; Se estiver, retorna

	cmp 	byte ptr dl, 13
	je 		transformaEmBarcode_fim_traducao

	cmp 	byte ptr dl, 10
	je 		transformaEmBarcode_fim_traducao

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
	call transforma_em_barcode_exec
	jmp transformaEmBarcode_loop

transforma_em_barcode_exec:
	push 	bx
	lea 	bx, BarCodeTable
	add 	bx, cx
	mov 	dl, [bx]
	pop bx
loop_acha_primeiro_0:
	shl	 dl, 1
	jc loop_coloca_valores_0
	jmp loop_acha_primeiro_0

loop_coloca_valores_0:
	mov  ax, 30h
	adc  ax, 0

	mov	 [si], ax
	inc si

	cmp 	dl, 0
	je  	loop_coloca_valores_0_acaba

	shl 	dl, 1
	jmp 	loop_coloca_valores_0

loop_coloca_valores_0_acaba:
	
	cmp 	cx, 10
	jg 		loop_coloca_valores_0_acaba_final
	push bx
	push dx
	mov 	dl, [bx]

	cmp 	ColocaSeparador, 0
	je  	pula_coloca_zero
	
	cmp     byte ptr dl, 0    ; Verifica se o buffer está vazio
	je      pula_coloca_zero    ; Se estiver, retorna

	cmp 	byte ptr dl, 13
	je 		pula_coloca_zero

	cmp 	byte ptr dl, 10
	je 		pula_coloca_zero
	
	mov 	[si], '0'
	inc 	si
pula_coloca_zero:
	pop dx
	pop bx
	
loop_coloca_valores_0_acaba_final:
	ret

transformaEmBarcode_fim_traducao:
    mov     byte ptr [di], 0      ; Adiciona terminador null no final do ChecksumBuffer
    push    cx                    ; Salva CX
    push    bx
    push    di
    push    si
    push    ax

    ; Calcula o comprimento da palavra
    mov     cl, 0                 ; Zera CL (contador de caracteres)
    lea     di, ChecksumBuffer    ; Ponteiro para o início do buffer
loop_conta_palavras_checksum:
    cmp     byte ptr [di], 0AH      ; Verifica o final da palavra
    je      loop_conta_palavras_end
    inc     di                    ; Avança para o próximo caractere
    inc     cl                    ; Incrementa o comprimento
    jmp     loop_conta_palavras_checksum

loop_conta_palavras_end:
    mov     Pesochecksum, cl      ; Define o peso inicial como o comprimento da palavra

    lea     si, ChecksumBuffer    ; Ponteiro para o início do buffer
    cmp     Pesochecksum, 0
    jz      erro_linha_em_branco

    mov     ChecksumTotal, 0      ; Zera o ChecksumTotal
loop_calcula_checksum:
    mov     al, [si]              ; Carrega o próximo byte do ChecksumBuffer em AL
    cmp     al, 0                 ; Verifica se chegou ao final do buffer
    je      checksum_done

    ; Ignora caracteres indesejados (CR e LF)
    cmp     al, 0Dh               ; CR
    je      ignora_caractere
    cmp     al, 0Ah               ; LF
    je      ignora_caractere

    ; Verifica se é numérico
    cmp     al, '0'
    jb      ignora_caractere
    cmp     al, '9'
    ja      ignora_caractere

    ; Converte o caractere numérico de ASCII para número
    sub     al, '0'               ; Converte de ASCII para número
    mov     ah, 0                 ; Garante que AH está zerado
    mul     Pesochecksum          ; Multiplica pelo peso

    ; Soma ao total do checksum
    add     ChecksumTotal, ax

    ; Diagnóstico: imprime o caractere processado
    ;mov     dl, [si]
    ;mov     ah, 2                 ; Interrupção do DOS para imprimir caractere
    ;int     21h
    ;lea     bx, MsgNewLine
    ;call    printf_s

ignora_caractere:
    ; Ignora o caractere e avança no buffer
    inc     si                    ; Avança para o próximo caractere
    dec     Pesochecksum          ; Reduz o peso
    cmp     Pesochecksum, 0
    jnz     loop_calcula_checksum

checksum_done:
    ; Salva registradores na pilha
    push    ax
    push    bx
    push    cx
    push    dx

    ; Calcula o resto da divisão do ChecksumTotal por 11
    mov     ax, ChecksumTotal      ; Carrega o ChecksumTotal em AX
    mov     bl, 11                 ; Define o divisor como 11
    div     bl                     ; AL = Quociente, AH = Resto

    ; AH contém o resto da divisão
    mov     cl, ah                 ; Move o resto para CL
    xor     ah, ah                 ; Limpa AH para evitar resíduos


    ; Imprime o valor do resto (divisão do checksum por 11)
    push    ax                     ; Salva AX antes da exibição
    mov     ax, cx                 ; Move o valor do resto para AX
	mov 	Checksum, ax
    call    print_number           ; Imprime o valor do checksum dividido por 11
    lea     bx, MsgNewLine         ; Prepara nova linha
    call    printf_s
    pop     ax                     ; Restaura AX

    ; Restaura registradores
    pop     dx
    pop     cx
    pop     bx
    pop     ax

    ; Continua para a próxima etapa
    jmp     termina_calculo_checksum

erro_caractere_invalido:
    ; Mensagem de erro para caracteres inválidos
    lea     bx, MsgErrorCaracterInvalido
    call    printf_s
    jmp     termina_calculo_checksum

erro_linha_em_branco:
    ; Mensagem de erro para linha em branco
    lea     bx, MsgLinhaEmBranco
    call    printf_s
	lea 	bx, MsgNewLine
	call    printf_s
	jmp     termina_calculo_checksum

termina_calculo_checksum:
    ; Restaura registradores salvos e retorna
    pop     ax
    pop     si
    pop     di
    pop     bx
    pop     cx
	
	mov 	ColocaSeparador, 0
	mov 	cx, Checksum
	call transforma_em_barcode_exec
	mov 	ColocaSeparador, 1
	mov      cx, 11
	call     transforma_em_barcode_exec
    ret


transformaEmBarcode endp


;
;--------------------------------------------------------------------
;Função:Converte um ASCII-DECIMAL para HEXA
;Entra: (S) -> DS:BX -> Ponteiro para o string de origem
;Sai:	(A) -> AX -> Valor "Hex" resultante
;Algoritmo:
;	A = 0;
;	while (*S!='\0') {
;		A = 10 * A + (*S - '0')
;		++S;
;	}
;	return
;--------------------------------------------------------------------
atoi	proc near

		; A = 0;
		mov		ax,0
		
atoi_2:
		; while (*S!='\0') {
		cmp		byte ptr[bx], 0
		jz		atoi_1

		; 	A = 10 * A
		mov		cx,10
		mul		cx

		; 	A = A + *S
		mov		ch,0
		mov		cl,[bx]
		add		ax,cx

		; 	A = A - '0'
		sub		ax,'0'

		; 	++S
		inc		bx
		
		;}
		jmp		atoi_2

atoi_1:
		; return
		ret

atoi	endp


;--------------------------------------------------------------------
; Função para imprimir um número na tela
; Entrada: AX contém o número a ser impresso
;--------------------------------------------------------------------
print_number proc near
    push    ax                    ; Salva AX
    push    dx                    ; Salva DX
    xor     cx, cx                ; Zera CX (contador de dígitos)

    ; Calcula os dígitos do número (armazenados na pilha)
print_number_loop:
    xor     dx, dx                ; Zera DX
    div     word ptr Divisor10    ; Divide AX por 10 (quociente em AX, resto em DX)
    push    dx                    ; Armazena o dígito na pilha
    inc     cx                    ; Incrementa o contador de dígitos
    test    ax, ax                ; Verifica se o quociente é 0
    jnz     print_number_loop     ; Continua se ainda houver dígitos

    ; Imprime os dígitos na ordem correta
print_number_output:
    pop     dx                    ; Recupera o próximo dígito
    add     dl, '0'               ; Converte o dígito para ASCII
    mov     ah, 2                 ; Função para imprimir caractere
    int     21h                   ; Chama a interrupção do DOS
    loop    print_number_output   ; Continua até imprimir todos os dígitos

    pop     dx                    ; Restaura DX
    pop     ax                    ; Restaura AX
    ret
print_number endp

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


	



