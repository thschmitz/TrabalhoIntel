	.model small
	.stack

	.data

BUFF_SIZE	equ 100 ; tam. máximo dos dados lidos no buffer

NomeArq	db "arq.txt",0    ; nome arq. terminado com \0
BuffArq	db BUFF_SIZE dup(?)	; buffer para dados lidos do arquivo
BytesLidos	dw ?	; guarda quantidade de bytes lidos
HandleArq dw ?		; guarda handle do arquivo
MsgErroAbr	db "Erro ao abrir arquivo!$"	; msg de erro ao abrir arquivo, terminada em $
MsgErroLer	db "Erro ao ler arquivo!$"		; msg de erro ao ler arquivo, terminada em $

	.code
	.startup

	; abre arquivo
	lea dx,NomeArq
	mov al,0
	mov ah,3dh
	int 21h ; CF == 0 se OK
	jc ErroAbrir ; se deu erro, imprime uma msg na tela
	mov HandleArq,ax

	; le arquivo - bx tem o handle
	mov bx,HandleArq
	lea dx,BuffArq
	mov ah,3fh
	mov cx,BUFF_SIZE
	int 21h ; CF == 0 se OK, AX tem bytes lidos
	jc ErroLer
	mov BytesLidos,ax

	; adiciona o $ no final do buffer de arquivo (para usarmos putmsg)
	lea bx,BuffArq
	mov si,BytesLidos
	mov byte ptr [bx+si],'$'
		
	; escreve na tela o dado lido com putmsg
	lea dx,BuffArq
	mov ah,9
	int 21h

	; fecha arquivo
	mov ah, 3eh
	mov bx,HandleArq
	jmp Fim

ErroAbrir:
	lea dx,MsgErroAbr
	mov ah,9
	int 21h
	jmp Fim
ErroLer:
	lea dx,MsgErroLer
	mov ah,9
	int 21h

Fim:
	.exit
	END