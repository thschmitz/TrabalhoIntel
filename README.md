# Projeto: Manipulador de Código de Barras "Code 11"

Este projeto implementa dois programas para manipulação do código de barras conhecido como **Code 11**: um **Gerador de Código de Barras** e um **Leitor de Código de Barras**. Foi desenvolvido como parte da disciplina **Arquitetura e Organização de Computadores I** na **UFRGS**.

## Sobre o Code 11

O **Code 11** é um padrão de código de barras que representa números (`0-9`) e o símbolo `"-"`. Ele é composto por barras de diferentes larguras, alternando entre preto e branco. Para garantir integridade, cada sequência inclui:
- Um símbolo de início/término (**SS**).
- Um dígito verificador calculado através de uma soma ponderada.

Para mais informações, consulte [Code 11 - Barcode Island (Wayback Machine)](https://web.archive.org/web/20070202060711/http://www.barcodeisland.com/code11.phtml).

## Programas Implementados

### 1. Gerador de Código de Barras
O programa lê um arquivo chamado **`IN.TXT`** com sequências numéricas e gera o arquivo **`OUT.BAR`** com a codificação correspondente em barras. As funcionalidades incluem:
- Validação das entradas e cálculo do dígito verificador.
- Geração do código de barras conforme o padrão **Code 11**.
- Tratamento de erros de entrada, exibindo mensagens na tela e anotando erros no arquivo de saída.

#### Formato do Arquivo de Entrada (`IN.TXT`):
START [linhas de sequências numéricas] STOP

#### Formato do Arquivo de Saída (`OUT.BAR`):
START [linhas com códigos de barras gerados] STOP




## Requisitos
- Processador: **Intel 8086**.
- Ferramentas: Assembler compatível com o 8086.

## Como Executar
1. Compile o programa utilizando um montador compatível.
2. Certifique-se de que os arquivos de entrada (`IN.TXT` ou `IN.BAR`) estão no formato correto.
3. Execute o programa e verifique os arquivos gerados (`OUT.BAR` ou `OUT.TXT`).

## Exemplo de Uso
### Gerador
Entrada (`IN.TXT`):
START 123-45 6789 STOP

Saída (`OUT.BAR`):
START 1011001 1001011 1010011 ... STOP



## Observações
- O código está comentado para facilitar a compreensão.
- Erros no formato de entrada ou na geração/decodificação são tratados com mensagens claras.

## Licença
Este projeto é destinado apenas para fins educacionais.

---


