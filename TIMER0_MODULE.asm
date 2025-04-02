;;			  CONFIGURA��O DO TIMER0 MODULE
;;    VERS�O: 1.0					DATA: 06/02/25
;;
;; AUTORA: VICTORIA MONTEIRO PONTES
;;
;;			    DESCRI��O DO ARQUIVO
;; ----------------------------------------------------------------------------
;; ESTE ARQUIVO EST� DESTINADO PARA A CONFIGURA��O B�SICA DO TIMER0 MODULE LE-
;; VANDO EM CONTA TODOS OS SEUS ASPECTOS E MODALIDADES DE USO, COMO USO DE 
;; PRESCALERS PARA A CONFIGURA��O DE CLOCK, MODO DE USO DO M�DULO (TIMER MODE OU
;; COUNTER MODE) E COMOM ASSOCI�-LOS A UM PINO DE SA�DA GP4. O TIMER DEVE SER 
;; CAPAZ DE CHAMAR A FUN��O DE TOGGLE_LED A CADA 500ms.
;; 
;; 
;;  
;; 
;; 

;; OBSERVA��O 2: AS CONFIGURA��ES CONTINUAM AS MESMAS EXIGIDAS NO PDF


    ;******************************************************************************
;*			ARQUIVO DE DEFINI��ES
;******************************************************************************

#include "p12f675.inc"

; CONFIG
; __config 0xF1FF
 __CONFIG _FOSC_EXTRCCLK & _WDTE_OFF & _PWRTE_ON & _MCLRE_OFF & _BOREN_OFF & _CP_OFF & _CPD_OFF
 
 
 ;*******************************************************************************
;*			PAGINA��O DE MEM�RIA
;*******************************************************************************

#DEFINE	    BANK0 BCF STATUS,RP0 ;SETA BANK 0 DE MEM�RIA
#DEFINE	    BANK1 BSF STATUS,RP0 ;SETA BANK 1 DE MEM�RIA

;*******************************************************************************
;*			    VARI�VEIS
;*******************************************************************************

CBLOCK	    0X20
 
    CONTADOR_TRANSBORDO
    W_TEMP  ;SALVA VALOR DO REGISTRADOR TEMP, PARA TRATAR INTERRUP��ES
    
ENDC

    ; TODO INSERT CONFIG CODE HERE USING CONFIG BITS GENERATOR

RES_VECT  CODE    0x0000            ; processor reset vector
    ORG	    0X00
    GOTO    INICIO	;RETORNA AO PROGRAMA PRINCIPAL
  
    ORG     0x04              ; ENDERE�O DE INTERRUP��O
    GOTO    TRATA_INT	    ;FUN��O QUE TRATA INTERRUP��O

    
; TODO ADD INTERRUPTS HERE IF USED

MAIN_PROG CODE                      ; let linker place main program

INICIO
    
    BANK1
    MOVLW   B'00010111' ; CONFIGURA PRESCALER 1:256, PARA TIMER0 MODULE COM CLK
    MOVWF   OPTION_REG  ; INTERNO
    
    
    MOVLW   B'10100100'	; HABILITA INTERRRUP��O E FLAG DE INTERRUP��O 
    MOVWF   INTCON	;QUANDO H� TRANSBO RDO
    
    CLRF ANSEL		    ;DIGITAL I/O
    MOVLW B'00000000'
    MOVWF TRISIO	    ; TUDO COMO SA�DA
    
    BANK0
    CLRWDT	;CLEAR WDT
    CLRF    TMR0; LIMPA TMR0 E PRESCALER
    CLRF    GPIO    ;LIMPA PINOS DE SA�DA
    
    

    GOTO MAIN_LOOP	    ;VOLTA PARA IN�CIO


MAIN_LOOP
    GOTO MAIN_LOOP


TOGGLE_LED
    ;LE PINO DE SA�DA GP4
    BTFSS   GPIO,0	;TEM 0 NO PINO?
    BSF	    GPIO, 0;SE SIM, SETA PINO PARA 1   
    BCF	    GPIO, 0; SE N�O, SETA PINO PARA 0
		;SE N�O, FAZ NADA
    RETURN
    
    
TRATA_INT   
    BTFSS   INTCON, T0IF  ; FOI O TIMER0?
    RETFIE               ; N�O, RETORNA AO PROGRAMA PRINCIPAL
    BCF     INTCON, T0IF  ; SE SIM, LIMPAR FLAG
    
    INCF    CONTADOR_TRANSBORDO, F  ;INCREMENTA CONTADOR DE TRANSBORDO
    MOVF    CONTADOR_TRANSBORDO, W
    SUBLW   B'00001000'           ; CONTADOR_TRANSBORDO - 8 � IGUAL A ZERO?
    BTFSS   STATUS, Z
    RETFIE                ; SE N�O, VOLTAR AO PROGRAMA PRINCIPAL

    CLRF    CONTADOR_TRANSBORDO	;SE SIM, LIMPA CONTADOR
    CALL    TOGGLE_LED  ; E CHAMA FUN��O
    RETFIE                ; DEPOIS RETORNA DA INTERRUP��O

    
END