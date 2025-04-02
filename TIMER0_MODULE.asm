;;			  CONFIGURAÇÃO DO TIMER0 MODULE
;;    VERSÃO: 1.0					DATA: 06/02/25
;;
;; AUTORA: VICTORIA MONTEIRO PONTES
;;
;;			    DESCRIÇÃO DO ARQUIVO
;; ----------------------------------------------------------------------------
;; ESTE ARQUIVO ESTÁ DESTINADO PARA A CONFIGURAÇÃO BÁSICA DO TIMER0 MODULE LE-
;; VANDO EM CONTA TODOS OS SEUS ASPECTOS E MODALIDADES DE USO, COMO USO DE 
;; PRESCALERS PARA A CONFIGURAÇÃO DE CLOCK, MODO DE USO DO MÓDULO (TIMER MODE OU
;; COUNTER MODE) E COMOM ASSOCIÁ-LOS A UM PINO DE SAÍDA GP4. O TIMER DEVE SER 
;; CAPAZ DE CHAMAR A FUNÇÃO DE TOGGLE_LED A CADA 500ms.
;; 
;; 
;;  
;; 
;; 

;; OBSERVAÇÃO 2: AS CONFIGURAÇÕES CONTINUAM AS MESMAS EXIGIDAS NO PDF


    ;******************************************************************************
;*			ARQUIVO DE DEFINIÇÕES
;******************************************************************************

#include "p12f675.inc"

; CONFIG
; __config 0xF1FF
 __CONFIG _FOSC_EXTRCCLK & _WDTE_OFF & _PWRTE_ON & _MCLRE_OFF & _BOREN_OFF & _CP_OFF & _CPD_OFF
 
 
 ;*******************************************************************************
;*			PAGINAÇÃO DE MEMÓRIA
;*******************************************************************************

#DEFINE	    BANK0 BCF STATUS,RP0 ;SETA BANK 0 DE MEMÓRIA
#DEFINE	    BANK1 BSF STATUS,RP0 ;SETA BANK 1 DE MEMÓRIA

;*******************************************************************************
;*			    VARIÁVEIS
;*******************************************************************************

CBLOCK	    0X20
 
    CONTADOR_TRANSBORDO
    W_TEMP  ;SALVA VALOR DO REGISTRADOR TEMP, PARA TRATAR INTERRUPÇÕES
    
ENDC

    ; TODO INSERT CONFIG CODE HERE USING CONFIG BITS GENERATOR

RES_VECT  CODE    0x0000            ; processor reset vector
    ORG	    0X00
    GOTO    INICIO	;RETORNA AO PROGRAMA PRINCIPAL
  
    ORG     0x04              ; ENDEREÇO DE INTERRUPÇÃO
    GOTO    TRATA_INT	    ;FUNÇÃO QUE TRATA INTERRUPÇÃO

    
; TODO ADD INTERRUPTS HERE IF USED

MAIN_PROG CODE                      ; let linker place main program

INICIO
    
    BANK1
    MOVLW   B'00010111' ; CONFIGURA PRESCALER 1:256, PARA TIMER0 MODULE COM CLK
    MOVWF   OPTION_REG  ; INTERNO
    
    
    MOVLW   B'10100100'	; HABILITA INTERRRUPÇÃO E FLAG DE INTERRUPÇÃO 
    MOVWF   INTCON	;QUANDO HÁ TRANSBO RDO
    
    CLRF ANSEL		    ;DIGITAL I/O
    MOVLW B'00000000'
    MOVWF TRISIO	    ; TUDO COMO SAÍDA
    
    BANK0
    CLRWDT	;CLEAR WDT
    CLRF    TMR0; LIMPA TMR0 E PRESCALER
    CLRF    GPIO    ;LIMPA PINOS DE SAÍDA
    
    

    GOTO MAIN_LOOP	    ;VOLTA PARA INÍCIO


MAIN_LOOP
    GOTO MAIN_LOOP


TOGGLE_LED
    ;LE PINO DE SAÍDA GP4
    BTFSS   GPIO,0	;TEM 0 NO PINO?
    BSF	    GPIO, 0;SE SIM, SETA PINO PARA 1   
    BCF	    GPIO, 0; SE NÃO, SETA PINO PARA 0
		;SE NÃO, FAZ NADA
    RETURN
    
    
TRATA_INT   
    BTFSS   INTCON, T0IF  ; FOI O TIMER0?
    RETFIE               ; NÃO, RETORNA AO PROGRAMA PRINCIPAL
    BCF     INTCON, T0IF  ; SE SIM, LIMPAR FLAG
    
    INCF    CONTADOR_TRANSBORDO, F  ;INCREMENTA CONTADOR DE TRANSBORDO
    MOVF    CONTADOR_TRANSBORDO, W
    SUBLW   B'00001000'           ; CONTADOR_TRANSBORDO - 8 É IGUAL A ZERO?
    BTFSS   STATUS, Z
    RETFIE                ; SE NÃO, VOLTAR AO PROGRAMA PRINCIPAL

    CLRF    CONTADOR_TRANSBORDO	;SE SIM, LIMPA CONTADOR
    CALL    TOGGLE_LED  ; E CHAMA FUNÇÃO
    RETFIE                ; DEPOIS RETORNA DA INTERRUPÇÃO

    
END